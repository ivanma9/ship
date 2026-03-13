import { useCallback, useEffect, useMemo, useRef, useState, lazy, Suspense } from 'react';
import { useNavigate } from 'react-router-dom';
import { EditorSkeleton } from '@/components/ui/EditorSkeleton';
import { LazyErrorBoundary } from '@/components/ui/LazyErrorBoundary';

const Editor = lazy(() => import('@/components/Editor').then(m => ({ default: m.Editor })));
import { PropertiesPanel } from '@/components/sidebars/PropertiesPanel';
import { WeeklyReviewSubNav } from '@/components/review/WeeklyReviewSubNav';
import { useWeeklyReviewActions } from '@/hooks/useWeeklyReviewActions';
import type {
  PanelDocument,
  WikiPanelProps,
  IssuePanelProps,
  ProjectPanelProps,
  SprintPanelProps,
  ProgramPanelProps,
} from '@/components/sidebars/PropertiesPanel';
import { DocumentTypeSelector, getMissingRequiredFields } from '@/components/sidebars/DocumentTypeSelector';
import type { DocumentType as SelectableDocumentType } from '@/components/sidebars/DocumentTypeSelector';
import { useAuth } from '@/hooks/useAuth';
import { PlanQualityBanner, RetroQualityBanner } from '@/components/PlanQualityBanner';
import { useAutoSave } from '@/hooks/useAutoSave';
import type { RequestError } from '@/lib/http-error';
import type { Person } from '@/components/PersonCombobox';
import type { BelongsTo } from '@ship/shared';

export type DocumentType = 'wiki' | 'issue' | 'project' | 'sprint' | 'program' | 'person' | 'weekly_plan' | 'weekly_retro';

// Base document interface - common properties across all document types
interface BaseDocument {
  id: string;
  title: string;
  document_type: DocumentType;
  created_at?: string;
  updated_at?: string;
  created_by?: string | null;
  properties?: Record<string, unknown>;
}

// Wiki document
interface WikiDocument extends BaseDocument {
  document_type: 'wiki';
  parent_id?: string | null;
  visibility?: 'private' | 'workspace';
}

// Issue document
interface IssueDocument extends BaseDocument {
  document_type: 'issue';
  state: string;
  priority: string;
  estimate: number | null;
  assignee_id: string | null;
  assignee_name?: string | null;
  assignee_archived?: boolean;
  program_id: string | null;
  sprint_id: string | null;
  source?: 'internal' | 'external';
  rejection_reason?: string | null;
  converted_from_id?: string | null;
  display_id?: string;
  belongs_to?: BelongsTo[];
}

// Project document
interface ProjectDocument extends BaseDocument {
  document_type: 'project';
  impact: number | null;
  confidence: number | null;
  ease: number | null;
  ice_score?: number | null;
  color: string;
  emoji: string | null;
  program_id: string | null;
  owner?: { id: string; name: string; email: string } | null;
  owner_id?: string | null;
  // RACI fields
  accountable_id?: string | null;
  consulted_ids?: string[];
  informed_ids?: string[];
  sprint_count?: number;
  issue_count?: number;
  converted_from_id?: string | null;
}

// Sprint document
interface SprintDocument extends BaseDocument {
  document_type: 'sprint';
  start_date: string;
  end_date: string;
  status: 'planning' | 'active' | 'completed';
  program_id: string | null;
  program_name?: string;
  issue_count?: number;
  completed_count?: number;
  plan?: string;
}

// Union type for all document types
export type UnifiedDocument = WikiDocument | IssueDocument | ProjectDocument | SprintDocument | BaseDocument;

// Sidebar data types
interface WikiSidebarData {
  teamMembers: Person[];
}

interface IssueSidebarData {
  teamMembers: Array<{ id: string; user_id: string; name: string }>;
  programs: Array<{ id: string; name: string; color?: string }>;
  projects?: Array<{ id: string; title: string; color?: string }>;
  onConvert?: () => void;
  onUndoConversion?: () => void;
  onAccept?: () => Promise<void>;
  onReject?: (reason: string) => Promise<void>;
  isConverting?: boolean;
  isUndoing?: boolean;
  onAssociationChange?: () => void;
}

interface ProjectSidebarData {
  programs: Array<{ id: string; name: string; emoji?: string | null }>;
  people: Person[];
  onConvert?: () => void;
  onUndoConversion?: () => void;
  isConverting?: boolean;
  isUndoing?: boolean;
}

interface SprintSidebarData {
  people?: Array<{ id: string; user_id: string; name: string }>;
  existingSprints?: Array<{ owner?: { id: string; name: string; email: string } | null }>;
}

interface ProgramSidebarData {
  people: Array<{ id: string; user_id: string; name: string; email: string }>;
}

export type SidebarData = WikiSidebarData | IssueSidebarData | ProjectSidebarData | SprintSidebarData | ProgramSidebarData;

interface UnifiedEditorProps {
  /** The document to edit */
  document: UnifiedDocument;
  /** Type-specific sidebar data */
  sidebarData?: SidebarData;
  /** Handler for document updates */
  onUpdate: (updates: Partial<UnifiedDocument>) => Promise<void>;
  /** Handler for back navigation */
  onBack?: () => void;
  /** Label for back button */
  backLabel?: string;
  /** Handler for document deletion */
  onDelete?: () => void;
  /** Room prefix for collaboration */
  roomPrefix?: string;
  /** Placeholder text for empty editor */
  placeholder?: string;
  /** Handler for creating sub-documents */
  onCreateSubDocument?: () => Promise<{ id: string; title: string } | null>;
  /** Handler for navigating to documents */
  onNavigateToDocument?: (docId: string) => void;
  /** Handler for document conversion events */
  onDocumentConverted?: (newDocId: string, newDocType: 'issue' | 'project') => void;
  /** Badge to show in header */
  headerBadge?: React.ReactNode;
  /** Whether to show the document type selector */
  showTypeSelector?: boolean;
  /** Handler for document type changes (if different from onUpdate) */
  onTypeChange?: (newType: DocumentType) => Promise<void>;
  /** Suffix displayed after the title in the header (e.g., author name) */
  titleSuffix?: string;
}

interface TitleConflictState {
  attemptedTitle: string;
  currentTitle: string;
  currentUpdatedAt: string;
}

/**
 * UnifiedEditor - Adaptive editor component that renders type-specific properties
 *
 * This component provides a unified editing experience for all document types
 * by adapting the properties sidebar based on document_type while using the
 * same TipTap editor for content.
 *
 * Usage:
 * ```tsx
 * <UnifiedEditor
 *   document={myDocument}
 *   sidebarData={typeSpecificData}
 *   onUpdate={handleUpdate}
 *   onBack={() => navigate(-1)}
 * />
 * ```
 */
export function UnifiedEditor({
  document,
  sidebarData = {},
  onUpdate,
  onBack,
  backLabel,
  onDelete,
  roomPrefix,
  placeholder,
  onCreateSubDocument,
  onNavigateToDocument,
  onDocumentConverted,
  headerBadge,
  showTypeSelector = false,
  onTypeChange,
  titleSuffix,
}: UnifiedEditorProps) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [isChangingType, setIsChangingType] = useState(false);
  const [titleSaveError, setTitleSaveError] = useState<string | null>(null);
  const [titleConflict, setTitleConflict] = useState<TitleConflictState | null>(null);
  const expectedUpdatedAtRef = useRef(document.updated_at);
  const expectedTitleRef = useRef(document.title);
  const latestLocalTitleRef = useRef(document.title);

  useEffect(() => {
    expectedUpdatedAtRef.current = document.updated_at;
    expectedTitleRef.current = document.title;
    latestLocalTitleRef.current = document.title;
  }, [document.id, document.title, document.updated_at]);

  useEffect(() => {
    setTitleSaveError(null);
    setTitleConflict(null);
  }, [document.id]);

  // Track missing required fields after type changes
  const missingFields = useMemo(() => {
    const selectableType = document.document_type as SelectableDocumentType;
    if (['wiki', 'issue', 'project', 'sprint'].includes(selectableType)) {
      // Build properties object from document
      const props: Record<string, unknown> = {
        ...document.properties,
        // Include top-level fields that might be required
        state: (document as IssueDocument).state,
        priority: (document as IssueDocument).priority,
        impact: (document as ProjectDocument).impact,
        confidence: (document as ProjectDocument).confidence,
        ease: (document as ProjectDocument).ease,
        start_date: (document as SprintDocument).start_date,
        end_date: (document as SprintDocument).end_date,
        status: (document as SprintDocument).status,
      };
      return getMissingRequiredFields(selectableType, props);
    }
    return [];
  }, [document]);

  // Auto-save title changes
  const throttledTitleSave = useAutoSave({
    onSave: async (title: string) => {
      if (!title) return;
      latestLocalTitleRef.current = title;
      const payload: Partial<UnifiedDocument> & { expected_updated_at?: string; expected_title?: string } = {
        title,
        expected_title: expectedTitleRef.current,
      };

      const result = await (onUpdate(payload as Partial<UnifiedDocument>) as Promise<{ title?: string; updated_at?: string } | void>);
      if (result && typeof result.title === 'string') {
        expectedTitleRef.current = result.title;
        latestLocalTitleRef.current = result.title;
      }
      if (result && typeof result.updated_at === 'string') {
        expectedUpdatedAtRef.current = result.updated_at;
      }
    },
    onSuccess: (savedTitle) => {
      expectedTitleRef.current = savedTitle;
      latestLocalTitleRef.current = savedTitle;
      setTitleSaveError(null);
      setTitleConflict(null);
    },
    onFailure: (error) => {
      const requestError = error as RequestError | undefined;
      if (requestError?.status === 409 && requestError.currentTitle && requestError.currentUpdatedAt) {
        expectedUpdatedAtRef.current = requestError.currentUpdatedAt;
        expectedTitleRef.current = requestError.currentTitle;
        setTitleConflict({
          attemptedTitle: requestError.attemptedTitle || latestLocalTitleRef.current || document.title,
          currentTitle: requestError.currentTitle,
          currentUpdatedAt: requestError.currentUpdatedAt,
        });
      }
      setTitleSaveError(getTitleSaveErrorMessage(error));
    },
  });

  const handleTitleChange = useCallback((title: string) => {
    latestLocalTitleRef.current = title;
    throttledTitleSave(title);
  }, [throttledTitleSave]);

  const handleTitleBlur = useCallback((title: string) => {
    latestLocalTitleRef.current = title;
    void throttledTitleSave.flush(title);
  }, [throttledTitleSave]);

  const handleRetryTitleSave = useCallback(async () => {
    if (!titleConflict) return;

    const retryTitle = latestLocalTitleRef.current || titleConflict.attemptedTitle;
    try {
      const result = await onUpdate({
        title: retryTitle,
        expected_title: titleConflict.currentTitle,
      } as Partial<UnifiedDocument>) as { updated_at?: string } | void;

      expectedTitleRef.current = retryTitle;
      latestLocalTitleRef.current = retryTitle;
      if (result?.updated_at) {
        expectedUpdatedAtRef.current = result.updated_at;
      }
      setTitleSaveError(null);
      setTitleConflict(null);
    } catch (error) {
      setTitleSaveError(getTitleSaveErrorMessage(error));
    }
  }, [onUpdate, titleConflict]);

  // Handle document type change
  const handleTypeChange = useCallback(async (newType: SelectableDocumentType) => {
    if (newType === document.document_type) return;

    setIsChangingType(true);
    try {
      if (onTypeChange) {
        await onTypeChange(newType as DocumentType);
      } else {
        await onUpdate({ document_type: newType as DocumentType } as Partial<UnifiedDocument>);
      }
    } finally {
      setIsChangingType(false);
    }
  }, [document.document_type, onTypeChange, onUpdate]);

  // Navigate to document handler
  const handleNavigateToDocument = useCallback((docId: string) => {
    if (onNavigateToDocument) {
      onNavigateToDocument(docId);
    } else {
      navigate(`/documents/${docId}`);
    }
  }, [navigate, onNavigateToDocument]);

  // Handle plan change (for sprint and project documents)
  const handlePlanChange = useCallback(async (plan: string) => {
    if (document.document_type !== 'sprint' && document.document_type !== 'project') return;
    // Update the plan property
    await onUpdate({ plan } as Partial<UnifiedDocument>);
  }, [document.document_type, onUpdate]);

  // Determine room prefix based on document type if not provided
  const effectiveRoomPrefix = roomPrefix || document.document_type;

  // Determine placeholder based on document type if not provided
  const effectivePlaceholder = placeholder || getDefaultPlaceholder(document.document_type);

  // Weekly plans and retros have review-mode sub-nav controls
  const isWeeklyDoc = document.document_type === 'weekly_plan' || document.document_type === 'weekly_retro';

  const weeklyReviewState = useWeeklyReviewActions(
    isWeeklyDoc
      ? {
          id: document.id,
          document_type: document.document_type as 'weekly_plan' | 'weekly_retro',
          properties: document.properties as { person_id?: string; project_id?: string; week_number?: number } | undefined,
        }
      : null
  );

  // Check if this document type can have its type changed
  const canChangeType = ['wiki', 'issue', 'project', 'sprint'].includes(document.document_type);

  // Build panel-specific props from sidebarData
  const panelProps = useMemo(() => {
    switch (document.document_type) {
      case 'wiki': {
        const wikiData = sidebarData as WikiSidebarData;
        return {
          teamMembers: wikiData.teamMembers || [],
          currentUserId: user?.id,
        } as WikiPanelProps;
      }
      case 'issue': {
        const issueData = sidebarData as IssueSidebarData;
        return {
          teamMembers: issueData.teamMembers || [],
          programs: issueData.programs || [],
          projects: issueData.projects || [],
          onConvert: issueData.onConvert,
          onUndoConversion: issueData.onUndoConversion,
          onAccept: issueData.onAccept,
          onReject: issueData.onReject,
          isConverting: issueData.isConverting,
          isUndoing: issueData.isUndoing,
          onAssociationChange: issueData.onAssociationChange,
        } as IssuePanelProps;
      }
      case 'project': {
        const projectData = sidebarData as ProjectSidebarData;
        return {
          programs: projectData.programs || [],
          people: projectData.people || [],
          onConvert: projectData.onConvert,
          onUndoConversion: projectData.onUndoConversion,
          isConverting: projectData.isConverting,
          isUndoing: projectData.isUndoing,
        } as ProjectPanelProps;
      }
      case 'sprint': {
        const sprintData = sidebarData as SprintSidebarData;
        return {
          people: sprintData.people || [],
          existingSprints: sprintData.existingSprints || [],
        } as SprintPanelProps;
      }
      case 'program': {
        const programData = sidebarData as ProgramSidebarData;
        return {
          people: programData.people || [],
        } as ProgramPanelProps;
      }
      default:
        return {};
    }
  }, [document.document_type, sidebarData, user?.id]);

  // Render the type-specific sidebar content via unified PropertiesPanel
  const typeSpecificSidebar = useMemo(() => {
    // Check if document type has a properties panel
    if (!['wiki', 'issue', 'project', 'sprint', 'program', 'weekly_plan', 'weekly_retro'].includes(document.document_type)) {
      return (
        <div className="p-4">
          <p className="text-xs text-muted">
            Document type: {document.document_type}
          </p>
        </div>
      );
    }

    return (
      <PropertiesPanel
        document={document as PanelDocument}
        panelProps={panelProps}
        onUpdate={onUpdate as (updates: Partial<PanelDocument>) => Promise<void>}
        highlightedFields={missingFields}
        weeklyReviewState={weeklyReviewState}
      />
    );
  }, [document, panelProps, onUpdate, missingFields, weeklyReviewState]);

  // Compose full sidebar with type selector
  const sidebar = useMemo(() => {
    // If we're not showing the type selector, just return the type-specific sidebar
    if (!showTypeSelector || !canChangeType) {
      return typeSpecificSidebar;
    }

    // Add type selector at the top
    return (
      <div className="flex flex-col h-full">
        {/* Type Selector */}
        <div className="p-4 border-b border-border">
          <DocumentTypeSelector
            value={document.document_type as SelectableDocumentType}
            onChange={handleTypeChange}
            disabled={isChangingType}
          />
          {missingFields.length > 0 && (
            <p className="mt-2 text-xs text-amber-500">
              Please fill in required fields: {missingFields.join(', ')}
            </p>
          )}
        </div>
        {/* Type-specific sidebar */}
        <div className="flex-1 overflow-auto pb-20">
          {typeSpecificSidebar}
        </div>
      </div>
    );
  }, [showTypeSelector, canChangeType, typeSpecificSidebar, document.document_type, handleTypeChange, isChangingType, missingFields]);

  if (!user) {
    return null;
  }

  // Weekly plans and retros have computed titles (includes person name) - make read-only
  const isTitleReadOnly = document.document_type === 'weekly_plan' || document.document_type === 'weekly_retro';

  // AI quality banner — triggers analysis on content changes from the editor
  const [editorContent, setEditorContent] = useState<Record<string, unknown> | null>(null);
  const [aiScoringAnalysis, setAiScoringAnalysis] = useState<{ planAnalysis?: unknown; retroAnalysis?: unknown } | null>(null);

  // Prevent stale AI feedback from leaking when navigating to a different document.
  useEffect(() => {
    setEditorContent(null);
    setAiScoringAnalysis(null);
  }, [document.id]);

  const handlePlanAnalysisChange = useCallback((analysis: unknown) => {
    setAiScoringAnalysis(analysis ? { planAnalysis: analysis } : null);
  }, []);

  const handleRetroAnalysisChange = useCallback((analysis: unknown) => {
    setAiScoringAnalysis(analysis ? { retroAnalysis: analysis } : null);
  }, []);

  const qualityBanner = useMemo(() => {
    if (document.document_type === 'weekly_plan') {
      return <PlanQualityBanner documentId={document.id} editorContent={editorContent} onAnalysisChange={handlePlanAnalysisChange} />;
    }
    if (document.document_type === 'weekly_retro') {
      return <RetroQualityBanner documentId={document.id} editorContent={editorContent} planContent={null} onAnalysisChange={handleRetroAnalysisChange} />;
    }
    return undefined;
  }, [document.id, document.document_type, editorContent, handlePlanAnalysisChange, handleRetroAnalysisChange]);

  const combinedContentBanner = useMemo(() => {
    const autoSaveBanner = titleSaveError ? (
      <div
        role="alert"
        className="rounded-md border border-amber-500/40 bg-amber-500/10 px-3 py-2 text-sm text-amber-300"
      >
        <div className="space-y-2">
          <p>{titleSaveError}</p>
          {titleConflict ? (
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-xs text-amber-200/80">
                Server title: "{titleConflict.currentTitle}"
              </span>
              <button
                type="button"
                onClick={() => { void handleRetryTitleSave(); }}
                className="rounded border border-amber-300/40 px-2 py-1 text-xs font-medium text-amber-100 hover:bg-amber-500/10"
              >
                Retry my title
              </button>
            </div>
          ) : null}
        </div>
      </div>
    ) : null;

    if (!autoSaveBanner && !qualityBanner) {
      return undefined;
    }

    return (
      <div className="mb-4 space-y-3">
        {autoSaveBanner}
        {qualityBanner}
      </div>
    );
  }, [handleRetryTitleSave, qualityBanner, titleConflict, titleSaveError]);

  const secondaryHeader = useMemo(() => {
    if (!weeklyReviewState?.isReviewMode) return undefined;
    return <WeeklyReviewSubNav reviewState={weeklyReviewState} />;
  }, [weeklyReviewState]);

  return (
    <LazyErrorBoundary>
      <Suspense fallback={<EditorSkeleton />}>
        <Editor
          documentId={document.id}
          userName={user.name}
          initialTitle={document.title}
          onTitleChange={isTitleReadOnly ? undefined : handleTitleChange}
          onTitleBlur={isTitleReadOnly ? undefined : handleTitleBlur}
          titleReadOnly={isTitleReadOnly}
          onBack={onBack}
          backLabel={backLabel}
          onDelete={onDelete}
          roomPrefix={effectiveRoomPrefix}
          placeholder={effectivePlaceholder}
          onCreateSubDocument={onCreateSubDocument}
          onNavigateToDocument={handleNavigateToDocument}
          onDocumentConverted={onDocumentConverted}
          headerBadge={headerBadge}
          secondaryHeader={secondaryHeader}
          sidebar={sidebar}
          documentType={document.document_type}
          onPlanChange={document.document_type === 'sprint' || document.document_type === 'project' ? handlePlanChange : undefined}
          contentBanner={combinedContentBanner}
          onContentChange={isWeeklyDoc ? setEditorContent : undefined}
          aiScoringAnalysis={isWeeklyDoc ? aiScoringAnalysis : undefined}
          titleSuffix={titleSuffix}
        />
      </Suspense>
    </LazyErrorBoundary>
  );
}

/**
 * Get default placeholder text based on document type
 */
function getDefaultPlaceholder(documentType: DocumentType): string {
  switch (documentType) {
    case 'wiki':
      return 'Start writing...';
    case 'issue':
      return 'Add a description...';
    case 'project':
      return 'Describe this project...';
    case 'sprint':
      return 'Add week goals, notes, or description...';
    case 'program':
      return 'Describe this program...';
    case 'person':
      return 'Add notes about this person...';
    default:
      return 'Start writing...';
  }
}

function getTitleSaveErrorMessage(error: unknown): string {
  const requestError = error as RequestError | undefined;
  if (requestError?.status === 409 || requestError?.code === 'WRITE_CONFLICT') {
    if (requestError.currentTitle) {
      return `Title changed elsewhere. Latest title: "${requestError.currentTitle}". Review and retry your title.`;
    }
    return 'Title changed elsewhere. Refresh to merge latest changes before editing again.';
  }
  return 'Title could not be saved. Changes are local only until save succeeds.';
}

// Re-export PropertiesPanel as the unified entry point for sidebars
export { PropertiesPanel } from '@/components/sidebars/PropertiesPanel';
export type {
  PanelDocument,
  PanelDocumentType,
  WikiPanelProps,
  IssuePanelProps,
  ProjectPanelProps,
  SprintPanelProps,
} from '@/components/sidebars/PropertiesPanel';
