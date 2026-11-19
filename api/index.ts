import type { IncomingMessage, ServerResponse } from 'node:http';
import { createConfiguredApp } from '../dist/app.setup.js';

type ExpressHandler = (req: IncomingMessage, res: ServerResponse) => void;

let handlerPromise: Promise<ExpressHandler> | null = null;

async function getHandler(): Promise<ExpressHandler> {
  if (!handlerPromise) {
    handlerPromise = (async () => {
      const app = await createConfiguredApp();
      await app.init();
      return app.getHttpAdapter().getInstance() as ExpressHandler;
    })();
  }
  return handlerPromise;
}

export default async function handler(
  req: IncomingMessage,
  res: ServerResponse,
): Promise<void> {
  const expressHandler = await getHandler();
  expressHandler(req, res);
}
