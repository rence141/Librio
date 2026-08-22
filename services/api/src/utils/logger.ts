// Simple logger wrapper using console
export const logger = {
  info: (msg: string, ...args: any[]) => console.log(`[INFO] ${msg}`, ...args),
  error: (msg: string, err?: any) => {
    if (err instanceof Error) {
      console.error(`[ERROR] ${msg}:`, err.message, err.stack);
    } else {
      console.error(`[ERROR] ${msg}`, err);
    }
  },
  warn: (msg: string, ...args: any[]) => console.warn(`[WARN] ${msg}`, ...args),
  debug: (msg: string, ...args: any[]) => console.log(`[DEBUG] ${msg}`, ...args),
};

export default logger;
