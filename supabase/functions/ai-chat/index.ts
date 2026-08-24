// supabase/functions/ai-chat/index.ts
//
// Librio AI Chat Edge Function
//
// Architecture:
//   Flutter App → Supabase Edge Function → FreeLLMAPI → LLM
//
// The FreeLLMAPI key is stored as a Supabase secret (FREELLM_API_KEY)
// and is NEVER exposed to the client.
//
// Required Supabase secrets:
//   FREELLM_API_KEY     — FreeLLMAPI unified key (freellmapi-...)
//   FREELLM_BASE_URL    — FreeLLMAPI base URL (default: https://freellmapi.co/v1)
//   AI_DEFAULT_MODEL    — Default model ID (default: gemini-2.0-flash)
//
// Rate limiting uses the ai_usage table (created via migration).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Constants ───────────────────────────────────────────────────────────────

const FREELLM_BASE_URL = Deno.env.get("FREELLM_BASE_URL") || "https://freellmapi.co/v1";
const FREELLM_API_KEY = Deno.env.get("FREELLM_API_KEY");
const AI_DEFAULT_MODEL = Deno.env.get("AI_DEFAULT_MODEL") || "claude-3.5-sonnet";

// AI Plans configuration (must match Flutter config/ai_plans.dart)
const AI_PLANS = {
  free: {
    requestsPerMinute: 5,
    requestsPerHour: 30,
    messagesPerDay: 100,
    maxInputTokens: 16000,
    maxOutputTokens: 2000,
    maxConcurrentRequests: 1,
    imageAnalysisPerDay: 5,
    documentAnalysisPerDay: 3,
  },
  paid: {
    requestsPerMinute: 15,
    requestsPerHour: 100,
    messagesPerDay: 500,
    maxInputTokens: 32000,
    maxOutputTokens: 4000,
    maxConcurrentRequests: 3,
    imageAnalysisPerDay: 30,
    documentAnalysisPerDay: 20,
  },
} as const;

// ─── Librio System Prompt (preserved from Flutter) ───────────────────────────

const LIBRIO_SYSTEM_PROMPT = `You are Librio, a helpful, intelligent study tutor.

Your job is to understand the user's actual input and respond to what they are asking or showing. Do not follow a generic greeting behavior when the user has provided meaningful content.

CORE RULES:

1. ACCURACY
- Only state information you are reasonably confident is correct.
- Never invent facts, names, dates, formulas, quotations, sources, or citations.
- If information is uncertain, clearly say so.

2. HONESTY
- If you do not know something, say:
  "I'm not sure about that."
- If there is insufficient information, say:
  "I don't have enough information to answer that accurately."
- Never fill gaps by guessing.

3. CLARITY
- Answer directly.
- Use simple, natural language.
- Avoid unnecessary introductions and repetition.
- Match the level of explanation to the user's question.

4. CONTEXT FIRST
- Always consider the user's latest message, attached files/images, and relevant conversation context before responding.
- Do not respond with a generic greeting when the user has already provided a question, image, document, text, or other meaningful input.

5. STUDY TUTOR ROLE
- Your primary purpose is helping with academic learning.
- You may briefly answer reasonable non-academic questions when useful, but naturally redirect toward studying when appropriate.
- Do not refuse a question merely because it is not explicitly academic.

6. PROVIDED MATERIALS
- When the user provides notes, documents, screenshots, images, or study materials, use them as context.
- Clearly distinguish between information found in the provided material and your own general knowledge.
- Never claim that something appears in the material if it does not.

IMAGE UNDERSTANDING — CRITICAL:

When an image is attached to the user's message, the image is part of the user's input and MUST be considered before generating the response.

Follow this process:

A. FIRST inspect and understand the image.
B. Identify relevant text, questions, UI elements, diagrams, charts, tables, documents, errors, or other visible information.
C. Determine whether the image itself contains something the user expects you to understand.
D. Combine the image with the user's accompanying text and conversation context.
E. Respond to the actual content instead of producing a generic greeting.

IMAGE RESPONSE RULES:

- Image upload does NOT mean the user wants a greeting.
- NEVER respond with:
  "Hello! I'm Librio, your study tutor..."
  or another generic introduction when an image contains meaningful content.
- If the image contains a question, answer it.
- If it contains homework, solve it or explain how to solve it.
- If it contains study material, explain or summarize it.
- If it contains a diagram, explain the diagram.
- If it contains a chart or table, interpret the relevant information.
- If it contains an error message, help diagnose the error.
- If it contains a screenshot of an application or website, analyze the visible UI/content when relevant.
- If it contains text, read and use that text as context.
- If the user asks what is shown in the image, describe what is actually visible.
- Do not invent details that cannot be seen.

IF IMAGE INTENT IS UNCLEAR:

Do not give a generic greeting.

Instead, briefly acknowledge what you can actually identify and ask a specific question.

Example:
"I can see a screenshot of a study conversation about strategic management. What would you like me to analyze or explain?"

IMPORTANT:
Do not ask this question if the user's accompanying message already tells you what they want.

RESPONSE PRIORITY:

When generating a response, prioritize information in this order:

1. The user's explicit request
2. Relevant information visible in uploaded images/files
3. Relevant conversation context
4. Reliable general knowledge
5. If none is sufficient, honestly state that you do not have enough information

GREETING RULE:

Only greet the user when a greeting is appropriate.

If the user uploads an image containing meaningful content, DO NOT greet first. Analyze the content and respond to it directly.

CORRECTION:
- If you discover that a previous response was incorrect, acknowledge the mistake and provide the corrected information.
- Do not defend or repeat an incorrect answer.

FINAL PRINCIPLE:

Understand first. Respond second.

Never let a generic assistant introduction override the user's actual input.
It is always better to say "I don't know" than to fabricate an answer.`;

// Title generation prompt
const TITLE_SYSTEM_PROMPT = `Generate a concise conversation title from the user's message. Rules: 3-7 words max, describe the main topic, no quotes, no "Chat" or "Conversation", use Title Case. Return ONLY the title, nothing else.`;

// ─── CORS ────────────────────────────────────────────────────────────────────

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Error helper ────────────────────────────────────────────────────────────

function errorResponse(status: number, code: string, message: string) {
  return new Response(
    JSON.stringify({ error: { code, message } }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

// ─── Auth ────────────────────────────────────────────────────────────────────

interface AuthUser {
  id: string;
  email: string;
  tier: string;
}

async function authenticate(req: Request): Promise<AuthUser | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) return null;

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) return null;

  // Fetch user tier from profile
  let tier = "free";
  try {
    const { data: profile } = await supabase
      .from("user_profiles")
      .select("subscription_tier")
      .eq("id", user.id)
      .single();
    if (profile?.subscription_tier) {
      tier = profile.subscription_tier;
    }
  } catch {
    // Default to free tier
  }

  return { id: user.id, email: user.email || "", tier };
}

// ─── Rate Limiting ───────────────────────────────────────────────────────────

async function checkRateLimit(
  supabaseUrl: string,
  supabaseServiceKey: string,
  userId: string,
  tier: string,
): Promise<{ allowed: boolean; reason?: string; remaining?: number }> {
  const planLimits = AI_PLANS[tier as keyof typeof AI_PLANS] || AI_PLANS.free;
  const now = new Date();
  const oneMinuteAgo = new Date(now.getTime() - 60 * 1000);
  const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // Check per-minute limit (only count successful requests)
  const { count: minuteCount, data: minuteData } = await supabase
    .from("ai_usage")
    .select("created_at", { count: "exact", head: false })
    .eq("user_id", userId)
    .eq("success", true)
    .gte("created_at", oneMinuteAgo.toISOString())
    .order("created_at", { ascending: true })
    .limit(1);

  if ((minuteCount || 0) >= planLimits.requestsPerMinute) {
    // Calculate when the oldest request ages out
    const oldestRequest = minuteData?.[0]?.created_at ? new Date(minuteData[0].created_at) : now;
    const resetTime = new Date(oldestRequest.getTime() + 60 * 1000);
    const resetTimeStr = resetTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    
    return {
      allowed: false,
      reason: `You've reached your AI limit for this minute.\nYour rate will return at ${resetTimeStr}.`,
      remaining: 0,
    };
  }

  // Check per-hour limit (only count successful requests)
  const { count: hourlyCount, data: hourlyData } = await supabase
    .from("ai_usage")
    .select("created_at", { count: "exact", head: false })
    .eq("user_id", userId)
    .eq("success", true)
    .gte("created_at", oneHourAgo.toISOString())
    .order("created_at", { ascending: true })
    .limit(1);

  if ((hourlyCount || 0) >= planLimits.requestsPerHour) {
    // Calculate when the oldest request ages out
    const oldestRequest = hourlyData?.[0]?.created_at ? new Date(hourlyData[0].created_at) : now;
    const resetTime = new Date(oldestRequest.getTime() + 60 * 60 * 1000);
    const resetTimeStr = resetTime.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    
    return {
      allowed: false,
      reason: `You've reached your AI limit for this hour.\nYour rate will return at ${resetTimeStr}.`,
      remaining: 0,
    };
  }

  // Check daily message limit (only count successful requests)
  const { count: dailyCount } = await supabase
    .from("ai_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("success", true)
    .gte("created_at", oneDayAgo.toISOString());

  if ((dailyCount || 0) >= planLimits.messagesPerDay) {
    // Daily limit resets at midnight
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    const resetTimeStr = tomorrow.toLocaleDateString([], { month: "short", day: "numeric" });
    
    return {
      allowed: false,
      reason: `You've reached today's AI usage limit.\nYour rate will return on ${resetTimeStr}.`,
      remaining: 0,
    };
  }

  return {
    allowed: true,
    remaining: planLimits.messagesPerDay - (dailyCount || 0),
  };
}

// ─── Record Usage ────────────────────────────────────────────────────────────

async function recordUsage(
  supabaseUrl: string,
  supabaseServiceKey: string,
  userId: string,
  model: string,
  inputTokens: number,
  outputTokens: number,
  success: boolean,
  latencyMs: number,
) {
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  await supabase.from("ai_usage").insert({
    user_id: userId,
    model_id: model,
    provider: "freellmapi",
    input_tokens: inputTokens,
    output_tokens: outputTokens,
    total_tokens: inputTokens + outputTokens,
    success,
    latency_ms: latencyMs,
  });
}

// ─── FreeLLMAPI Call ─────────────────────────────────────────────────────────

interface FreeLLMResponse {
  text: string;
  inputTokens: number;
  outputTokens: number;
  model: string;
}

async function callFreeLLMAPI(
  messages: Array<Record<string, any>>,
  model: string,
  stream: boolean,
  maxTokens: number,
): Promise<FreeLLMResponse> {
  if (!FREELLM_API_KEY) {
    throw new Error("FREELLM_API_KEY not configured");
  }

  const url = `${FREELLM_BASE_URL}/chat/completions`;
  const startTime = Date.now();

  console.log(`[FreeLLMAPI] Calling ${url} with model: ${model}`);
  console.log(`[FreeLLMAPI] Base URL: ${FREELLM_BASE_URL}`);
  console.log(`[FreeLLMAPI] API Key configured: ${FREELLM_API_KEY ? "yes" : "no"}`);

  let response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${FREELLM_API_KEY}`,
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: 0.3,
        top_p: 0.85,
        max_tokens: maxTokens,
        stream: false,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error(`[FreeLLMAPI] Error ${response.status}: ${body}`);

      if (response.status === 401) {
        throw new Error("INVALID_API_KEY");
      } else if (response.status === 429) {
        throw new Error("RATE_LIMIT_REACHED");
      } else if (response.status === 503) {
        throw new Error("PROVIDER_UNAVAILABLE");
      } else if (response.status >= 500) {
        throw new Error("SERVER_ERROR");
      } else {
        throw new Error("REQUEST_FAILED");
      }
    }

    console.log(`[FreeLLMAPI] Success: ${response.status}`);

    const data = await response.json();
    console.log(`[FreeLLMAPI] Response data: ${JSON.stringify(data).substring(0, 200)}`);
    
    const choices = data.choices;
    if (!choices || choices.length === 0) {
      throw new Error("NO_RESPONSE");
    }

    const text = choices[0].message?.content || "";
    const usage = data.usage || {};

    return {
      text,
      inputTokens: usage.prompt_tokens || 0,
      outputTokens: usage.completion_tokens || 0,
      model: data.model || model,
    };
  } catch (error) {
    console.error(`[FreeLLMAPI] Error: ${error instanceof Error ? error.message : String(error)}`);
    throw error;
  }
}

// ─── Main Handler ────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Handle health check (keep Railway warm)
  if (req.method === "GET") {
    return new Response(JSON.stringify({ status: "ok", timestamp: new Date().toISOString() }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (req.method !== "POST") {
    return errorResponse(405, "METHOD_NOT_ALLOWED", "Only POST and GET are supported.");
  }

  // ── 1. Authenticate ──
  const user = await authenticate(req);
  if (!user) {
    return errorResponse(401, "AUTH_REQUIRED", "Authentication required.");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // ── 2. Parse request ──
  let body;
  try {
    body = await req.json();
  } catch {
    return errorResponse(400, "INVALID_REQUEST", "Invalid JSON body.");
  }

  const {
    prompt,
    messages,
    model: requestedModel,
    imageContent,
    generateTitle,
    conversationContext,
  } = body;

  // ── 3. Title generation mode ──
  if (generateTitle && prompt) {
    try {
      const titleMessages = [
        { role: "system", content: TITLE_SYSTEM_PROMPT },
        { role: "user", content: prompt },
      ];

      const result = await callFreeLLMAPI(titleMessages, "auto", false, 30);
      const title = result.text.trim().replace(/["'`]/g, "");

      return new Response(
        JSON.stringify({ title: title || prompt.substring(0, 50) }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    } catch (error) {
      // Fallback: first 7 words
      const words = prompt.trim().split(/\s+/);
      const fallback = words.length <= 7 ? prompt.trim() : words.slice(0, 7).join(" ");
      return new Response(
        JSON.stringify({ title: fallback }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
  }

  // ── 4. Validate prompt ──
  if (!prompt && !messages) {
    return errorResponse(400, "INVALID_REQUEST", "Prompt or messages required.");
  }

  const model = requestedModel || AI_DEFAULT_MODEL;

  // ── 5. Rate limit check ──
  const rateLimit = await checkRateLimit(supabaseUrl, supabaseServiceKey, user.id, user.tier);
  if (!rateLimit.allowed) {
    return errorResponse(429, "RATE_LIMIT_EXCEEDED", rateLimit.reason || "Rate limit exceeded.");
  }

  // ── 6. Build messages ──
  const apiMessages: Array<Record<string, any>> = [
    { role: "system", content: LIBRIO_SYSTEM_PROMPT },
  ];

  // Add conversation context if provided
  if (conversationContext && Array.isArray(conversationContext)) {
    for (const msg of conversationContext) {
      if (msg.role && msg.content) {
        apiMessages.push({ role: msg.role, content: msg.content });
      }
    }
  }

  // Add current user message
  if (messages && Array.isArray(messages)) {
    // If full messages array is provided, use it (minus system - we add our own)
    for (const msg of messages) {
      if (msg.role === "system") continue; // We inject our own system prompt
      apiMessages.push(msg);
    }
  } else if (imageContent && Array.isArray(imageContent)) {
    // Vision format: array of content parts
    apiMessages.push({ role: "user", content: imageContent });
  } else {
    apiMessages.push({ role: "user", content: prompt });
  }

  // ── 7. Call FreeLLMAPI ──
  const startTime = Date.now();
  let result: FreeLLMResponse;
  try {
    result = await callFreeLLMAPI(apiMessages, model, false, 2048);
  } catch (error) {
    const message = error instanceof Error ? error.message : "UNKNOWN_ERROR";
    const latencyMs = Date.now() - startTime;

    // Record failed usage
    await recordUsage(supabaseUrl, supabaseServiceKey, user.id, model, 0, 0, false, latencyMs);

    // Map to clean error
    const errorMap: Record<string, { code: string; message: string; status: number }> = {
      "INVALID_API_KEY": { code: "PROVIDER_CONFIG_ERROR", message: "AI service is not properly configured.", status: 503 },
      "RATE_LIMIT_REACHED": { code: "PROVIDER_RATE_LIMIT", message: "The AI service is temporarily busy. Please try again in a moment.", status: 429 },
      "PROVIDER_UNAVAILABLE": { code: "PROVIDER_UNAVAILABLE", message: "AI service is temporarily unavailable.", status: 503 },
      "NO_RESPONSE": { code: "NO_RESPONSE", message: "The AI model returned no response.", status: 502 },
      "REQUEST_FAILED": { code: "REQUEST_FAILED", message: "Failed to reach AI service.", status: 502 },
      "SERVER_ERROR": { code: "SERVER_ERROR", message: "AI service experienced an error.", status: 502 },
    };

    const mapped = errorMap[message] || { code: "INTERNAL_ERROR", message: "An unexpected error occurred.", status: 500 };
    return errorResponse(mapped.status, mapped.code, mapped.message);
  }

  const latencyMs = Date.now() - startTime;

  // ── 8. Record usage ──
  await recordUsage(
    supabaseUrl,
    supabaseServiceKey,
    user.id,
    result.model,
    result.inputTokens,
    result.outputTokens,
    true,
    latencyMs,
  );

  // ── 9. Return response ──
  return new Response(
    JSON.stringify({
      text: result.text,
      model: result.model,
      provider: "freellmapi",
      usage: {
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
        totalTokens: result.inputTokens + result.outputTokens,
      },
      remaining: rateLimit.remaining,
    }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
