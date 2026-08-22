import { logger } from '../utils/logger';

export interface SafetyResult {
  safe: boolean;
  reason?: string;
  categories: string[];
}

/**
 * AI Safety guardrails service.
 *
 * Resource protection and content safety are separate systems.
 * This checks input and output for prohibited content.
 *
 * Does NOT rely exclusively on a system prompt — uses pattern-based
 * detection. In production, integrate with provider moderation APIs
 * or dedicated safety models.
 */
export class SafetyService {
  // Prohibited content patterns (simplified — extend for production)
  private readonly prohibitedPatterns: Array<{ pattern: RegExp; category: string; reason: string }> = [
    {
      pattern: /how\s+to\s+(make|build|create|manufacture)\s+(bomb|explosive|weapon|poison|chemical\s+weapon)/i,
      category: 'violence',
      reason: 'Requests for creating weapons or explosives are not allowed.',
    },
    {
      pattern: /(child|minor|underage)\s+(sexual|abuse|exploit)/i,
      category: 'csam',
      reason: 'Content involving child exploitation is strictly prohibited.',
    },
    {
      pattern: /how\s+to\s+(hack|breach|exploit|attack)\s+(a\s+)?(specific\s+)?(website|server|database|system|network)/i,
      category: 'cyberattack',
      reason: 'Requests for attacking specific targets are not allowed.',
    },
    {
      pattern: /(generate|create|write)\s+(malware|ransomware|virus|trojan|keylogger|rootkit)/i,
      category: 'malware',
      reason: 'Creating malware or malicious software is not allowed.',
    },
    {
      pattern: /(sell|distribute|traffic)\s+(drugs|narcotics|illegal\s+substances)/i,
      category: 'illegal_activity',
      reason: 'Content promoting illegal drug trafficking is not allowed.',
    },
  ];

  /**
   * Check input prompt for safety.
   */
  checkInput(prompt: string): SafetyResult {
    const categories: string[] = [];

    for (const rule of this.prohibitedPatterns) {
      if (rule.pattern.test(prompt)) {
        logger.warn({ category: rule.category }, 'Safety: input blocked');
        return {
          safe: false,
          reason: rule.reason,
          categories: [rule.category],
        };
      }
    }

    // Check for prompt injection attempts (simplified)
    if (/ignore\s+(all\s+)?(previous|prior)\s+instructions/i.test(prompt)) {
      categories.push('prompt_injection');
      logger.info('Safety: possible prompt injection detected (allowed with warning)');
    }

    return { safe: true, categories };
  }

  /**
   * Check output for safety.
   */
  checkOutput(text: string): SafetyResult {
    for (const rule of this.prohibitedPatterns) {
      if (rule.pattern.test(text)) {
        logger.warn({ category: rule.category }, 'Safety: output blocked');
        return {
          safe: false,
          reason: 'Generated content was filtered for safety.',
          categories: [rule.category],
        };
      }
    }

    return { safe: true, categories: [] };
  }
}

/** Singleton. */
let instance: SafetyService | null = null;
export function getSafetyService(): SafetyService {
  if (!instance) instance = new SafetyService();
  return instance;
}
