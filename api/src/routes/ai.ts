/**
 * AI analysis routes for plan and retro quality feedback.
 *
 * POST /api/ai/analyze-plan - Analyze plan quality (falsifiability + workload)
 * POST /api/ai/analyze-retro - Analyze retro quality (plan coverage + evidence)
 * GET /api/ai/status - Check if AI analysis is available
 */

import { Router, Response } from 'express';
import { AuthenticatedRequest, authHandler } from '../types/express.js';
import { authMiddleware } from '../middleware/auth.js';
import { analyzePlan, analyzeRetro, isAiAvailable, checkRateLimit } from '../services/ai-analysis.js';

type RouterType = ReturnType<typeof Router>;
const router: RouterType = Router();

// GET /api/ai/status - Check if AI analysis is available
router.get('/status', authMiddleware, authHandler((_req: AuthenticatedRequest, res: Response) => {
  res.json({ available: isAiAvailable() });
}));

// POST /api/ai/analyze-plan - Analyze weekly plan quality
router.post('/analyze-plan', authMiddleware, authHandler(async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.userId;
    const { content } = req.body;

    if (!content) {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    // Rate limit check
    if (!checkRateLimit(userId)) {
      res.status(429).json({ error: 'Rate limit exceeded. Max 10 analysis requests per hour.' });
      return;
    }

    const result = await analyzePlan(content);
    res.json(result);
  } catch (err) {
    console.error('Analyze plan error:', err);
    res.json({ error: 'ai_unavailable' });
  }
}));

// POST /api/ai/analyze-retro - Analyze weekly retro quality
router.post('/analyze-retro', authMiddleware, authHandler(async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.userId;
    const { retro_content, plan_content } = req.body;

    if (!retro_content) {
      res.status(400).json({ error: 'retro_content is required' });
      return;
    }

    if (!plan_content) {
      res.status(400).json({ error: 'plan_content is required' });
      return;
    }

    // Rate limit check
    if (!checkRateLimit(userId)) {
      res.status(429).json({ error: 'Rate limit exceeded. Max 10 analysis requests per hour.' });
      return;
    }

    const result = await analyzeRetro(retro_content, plan_content);
    res.json(result);
  } catch (err) {
    console.error('Analyze retro error:', err);
    res.json({ error: 'ai_unavailable' });
  }
}));

export default router;
