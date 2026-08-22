import { logger } from '../utils/logger';
import { ModelMeta } from '../config/guardrails.config';

export interface ProviderRequest {
  prompt: string;
  maxTokens: number;
  temperature?: number;
  systemPrompt?: string;
}

export interface ProviderResponse {
  text: string;
  inputTokens: number;
  outputTokens: number;
  finishReason: 'stop' | 'length' | 'safety' | 'error';
}

/**
 * Cloud provider abstraction.
 *
 * API keys exist ONLY on the backend. Never in Flutter source, APK,
 * web bundle, or public repos.
 *
 * Architecture: Client → Librio Backend → Provider API
 * NOT: Client → Provider API
 */
export class ProviderService {
  /**
   * Call a cloud provider. The model metadata determines which provider to use.
   */
  async call(model: ModelMeta, request: ProviderRequest): Promise<ProviderResponse> {
    switch (model.provider) {
      case 'openai':
        return this.callOpenAI(model, request);
      case 'anthropic':
        return this.callAnthropic(model, request);
      case 'gemini':
        return this.callGemini(model, request);
      case 'custom':
        return this.callCustom(model, request);
      default:
        throw new Error(`Unknown provider: ${model.provider}`);
    }
  }

  /**
   * OpenAI-compatible API call.
   * Key from env: OPENAI_API_KEY (NEVER sent to client)
   */
  private async callOpenAI(model: ModelMeta, request: ProviderRequest): Promise<ProviderResponse> {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      logger.error('OPENAI_API_KEY not configured');
      throw new Error('Cloud provider not configured');
    }

    const baseURL = process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';
    const model_name = process.env.OPENAI_MODEL || 'gpt-4o-mini';

    const response = await fetch(`${baseURL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: model_name,
        messages: [
          ...(request.systemPrompt ? [{ role: 'system', content: request.systemPrompt }] : []),
          { role: 'user', content: request.prompt },
        ],
        max_tokens: request.maxTokens,
        temperature: request.temperature ?? 0.7,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      logger.error({ status: response.status, errText }, 'OpenAI API error');
      throw new Error(`Provider error: ${response.status}`);
    }

    const data: any = await response.json();
    const choice = data.choices?.[0];
    const text = choice?.message?.content ?? '';
    const inputTokens = data.usage?.prompt_tokens ?? Math.ceil(request.prompt.length / 4);
    const outputTokens = data.usage?.completion_tokens ?? Math.ceil(text.length / 4);

    return {
      text,
      inputTokens,
      outputTokens,
      finishReason: choice?.finish_reason === 'length' ? 'length' : 'stop',
    };
  }

  /**
   * Anthropic API call.
   * Key from env: ANTHROPIC_API_KEY (NEVER sent to client)
   */
  private async callAnthropic(model: ModelMeta, request: ProviderRequest): Promise<ProviderResponse> {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      logger.error('ANTHROPIC_API_KEY not configured');
      throw new Error('Cloud provider not configured');
    }

    const model_name = process.env.ANTHROPIC_MODEL || 'claude-3-5-sonnet-20241022';

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: model_name,
        max_tokens: request.maxTokens,
        system: request.systemPrompt ?? 'You are Librio, a helpful academic tutor.',
        messages: [{ role: 'user', content: request.prompt }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      logger.error({ status: response.status, errText }, 'Anthropic API error');
      throw new Error(`Provider error: ${response.status}`);
    }

    const data: any = await response.json();
    const text = data.content?.map((c: any) => c.text).join('') ?? '';
    const inputTokens = data.usage?.input_tokens ?? Math.ceil(request.prompt.length / 4);
    const outputTokens = data.usage?.output_tokens ?? Math.ceil(text.length / 4);

    return { text, inputTokens, outputTokens, finishReason: 'stop' };
  }

  /**
   * Gemini API call.
   * Key from env: GEMINI_API_KEY (NEVER sent to client)
   */
  private async callGemini(model: ModelMeta, request: ProviderRequest): Promise<ProviderResponse> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      logger.error('GEMINI_API_KEY not configured');
      throw new Error('Cloud provider not configured');
    }

    const model_name = process.env.GEMINI_MODEL || 'gemini-1.5-flash';

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model_name}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: request.prompt }] }],
          generationConfig: { maxOutputTokens: request.maxTokens },
        }),
      },
    );

    if (!response.ok) {
      const errText = await response.text();
      logger.error({ status: response.status, errText }, 'Gemini API error');
      throw new Error(`Provider error: ${response.status}`);
    }

    const data: any = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join('') ?? '';
    const inputTokens = data.usageMetadata?.promptTokenCount ?? Math.ceil(request.prompt.length / 4);
    const outputTokens = data.usageMetadata?.candidatesTokenCount ?? Math.ceil(text.length / 4);

    return { text, inputTokens, outputTokens, finishReason: 'stop' };
  }

  /**
   * Custom/self-hosted provider.
   */
  private async callCustom(model: ModelMeta, request: ProviderRequest): Promise<ProviderResponse> {
    const baseURL = process.env.CUSTOM_AI_BASE_URL;
    const apiKey = process.env.CUSTOM_AI_API_KEY;
    if (!baseURL) {
      throw new Error('Custom provider not configured');
    }

    const response = await fetch(`${baseURL}/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(apiKey ? { 'Authorization': `Bearer ${apiKey}` } : {}),
      },
      body: JSON.stringify({
        prompt: request.prompt,
        max_tokens: request.maxTokens,
        temperature: request.temperature ?? 0.7,
      }),
    });

    if (!response.ok) {
      throw new Error(`Custom provider error: ${response.status}`);
    }

    const data: any = await response.json();
    const text = data.text ?? data.response ?? data.output ?? '';
    return {
      text,
      inputTokens: data.input_tokens ?? Math.ceil(request.prompt.length / 4),
      outputTokens: data.output_tokens ?? Math.ceil(text.length / 4),
      finishReason: 'stop',
    };
  }
}

/** Singleton. */
let instance: ProviderService | null = null;
export function getProviderService(): ProviderService {
  if (!instance) instance = new ProviderService();
  return instance;
}
