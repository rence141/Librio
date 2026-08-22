import { UsageService } from './usage.service';
import { SPENDING_LIMITS } from '../config/guardrails.config';
import { logger } from '../utils/logger';
import { getStore, KVStore } from './store.service';

export interface SpendingStatus {
  cloudEnabled: boolean;
  dailySpendUSD: number;
  dailyBudgetUSD: number;
  monthlySpendUSD: number;
  monthlyBudgetUSD: number;
  emergencyTriggered: boolean;
  reason?: string;
}

/**
 * Global spending protection service.
 *
 * Financial kill switch: if global thresholds are reached,
 * cloud AI is disabled while local AI continues working.
 *
 * Protects against: bugs, bot attacks, credential abuse,
 * unexpected traffic spikes, misconfigured quotas, provider price changes.
 */
export class BillingService {
  private killSwitchActive = false;

  constructor(
    private usageService: UsageService,
    private store: KVStore = getStore(),
  ) {}

  /**
   * Check if cloud AI is currently available.
   * Caches the result for 60 seconds to avoid DB hits on every request.
   */
  async checkCloudAvailable(): Promise<SpendingStatus> {
    // Check cached kill-switch state
    const cachedKill = await this.store.getString('billing:killswitch');
    if (cachedKill === '1') {
      return {
        cloudEnabled: false,
        dailySpendUSD: 0,
        dailyBudgetUSD: SPENDING_LIMITS.dailyBudgetUSD,
        monthlySpendUSD: 0,
        monthlyBudgetUSD: SPENDING_LIMITS.monthlyBudgetUSD,
        emergencyTriggered: true,
        reason: 'Emergency kill-switch active',
      };
    }

    const now = new Date();
    const daily = await this.usageService.getDailySpend(now);
    const monthly = await this.usageService.getMonthlySpend(now);

    // Check emergency threshold
    if (daily.estimatedCostUSD >= SPENDING_LIMITS.emergencyBudgetUSD) {
      this.killSwitchActive = true;
      await this.store.set('billing:killswitch', '1', 3600); // 1 hour cache
      logger.error({ dailySpend: daily.estimatedCostUSD }, 'BILLING: Emergency threshold reached! Cloud AI disabled.');
      return {
        cloudEnabled: false,
        dailySpendUSD: daily.estimatedCostUSD,
        dailyBudgetUSD: SPENDING_LIMITS.dailyBudgetUSD,
        monthlySpendUSD: monthly.estimatedCostUSD,
        monthlyBudgetUSD: SPENDING_LIMITS.monthlyBudgetUSD,
        emergencyTriggered: true,
        reason: 'Emergency spending threshold reached',
      };
    }

    // Check daily budget
    if (daily.estimatedCostUSD >= SPENDING_LIMITS.dailyBudgetUSD) {
      logger.warn({ dailySpend: daily.estimatedCostUSD }, 'BILLING: Daily budget reached. Cloud AI restricted.');
      return {
        cloudEnabled: false,
        dailySpendUSD: daily.estimatedCostUSD,
        dailyBudgetUSD: SPENDING_LIMITS.dailyBudgetUSD,
        monthlySpendUSD: monthly.estimatedCostUSD,
        monthlyBudgetUSD: SPENDING_LIMITS.monthlyBudgetUSD,
        emergencyTriggered: false,
        reason: 'Daily spending budget reached',
      };
    }

    // Check monthly budget
    if (monthly.estimatedCostUSD >= SPENDING_LIMITS.monthlyBudgetUSD) {
      logger.warn({ monthlySpend: monthly.estimatedCostUSD }, 'BILLING: Monthly budget reached. Cloud AI restricted.');
      return {
        cloudEnabled: false,
        dailySpendUSD: daily.estimatedCostUSD,
        dailyBudgetUSD: SPENDING_LIMITS.dailyBudgetUSD,
        monthlySpendUSD: monthly.estimatedCostUSD,
        monthlyBudgetUSD: SPENDING_LIMITS.monthlyBudgetUSD,
        emergencyTriggered: false,
        reason: 'Monthly spending budget reached',
      };
    }

    return {
      cloudEnabled: true,
      dailySpendUSD: daily.estimatedCostUSD,
      dailyBudgetUSD: SPENDING_LIMITS.dailyBudgetUSD,
      monthlySpendUSD: monthly.estimatedCostUSD,
      monthlyBudgetUSD: SPENDING_LIMITS.monthlyBudgetUSD,
      emergencyTriggered: false,
    };
  }

  /**
   * Manually activate the kill switch (admin override).
   */
  async activateKillSwitch(): Promise<void> {
    await this.store.set('billing:killswitch', '1', 86400); // 24 hours
    logger.error('BILLING: Kill switch manually activated');
  }

  /**
   * Deactivate the kill switch (admin override).
   */
  async deactivateKillSwitch(): Promise<void> {
    await this.store.del('billing:killswitch');
    this.killSwitchActive = false;
    logger.info('BILLING: Kill switch deactivated');
  }
}

/** Singleton. */
let instance: BillingService | null = null;
export function getBillingService(pool: any): BillingService {
  if (!instance) instance = new BillingService(new UsageService(pool));
  return instance;
}
