// Simple logger wrapper using console
// Supports both string and pino-style object logging:
//   logger.info('message')
//   logger.info({ userId: '123' }, 'message')
export const logger = {
  info: (msgOrObj: string | Record<string, unknown>, ...args: any[]) => {
    if (typeof msgOrObj === 'string') {
      console.log(`[INFO] ${msgOrObj}`, ...args);
    } else {
      console.log(`[INFO]`, msgOrObj, ...args);
    }
  },
  error: (msgOrObj: string | Record<string, unknown>, err?: any) => {
    if (typeof msgOrObj === 'string') {
      if (err instanceof Error) {
        console.error(`[ERROR] ${msgOrObj}:`, err.message, err.stack);
      } else {
        console.error(`[ERROR] ${msgOrObj}`, err);
      }
    } else {
      console.error(`[ERROR]`, msgOrObj, err);
    }
  },
  warn: (msgOrObj: string | Record<string, unknown>, ...args: any[]) => {
    if (typeof msgOrObj === 'string') {
      console.warn(`[WARN] ${msgOrObj}`, ...args);
    } else {
      console.warn(`[WARN]`, msgOrObj, ...args);
    }
  },
  debug: (msgOrObj: string | Record<string, unknown>, ...args: any[]) => {
    if (typeof msgOrObj === 'string') {
      console.log(`[DEBUG] ${msgOrObj}`, ...args);
    } else {
      console.log(`[DEBUG]`, msgOrObj, ...args);
    }
  },
};

export default logger;
