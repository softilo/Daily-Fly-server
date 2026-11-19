import { Logger } from '@nestjs/common';
import { createConfiguredApp } from './app.setup.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await createConfiguredApp();

  const port = parseInt(process.env.PORT || '5000', 10);
  await app.listen(port);
  logger.log(
    `TravelPilot backend listening on http://localhost:${port}/api/v1`,
  );
  logger.log(
    `Swagger documentation available at http://localhost:${port}/api/docs`,
  );
}

void bootstrap();
