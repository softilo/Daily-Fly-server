import { INestApplication, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import helmet from 'helmet';
import { AppModule } from './app.module.js';
import { AllExceptionsFilter } from './common/filters/http-exception.filter.js';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor.js';
import { RequestIdInterceptor } from './common/interceptors/request-id.interceptor.js';

export function configureApp(app: INestApplication): void {
  // Security headers & compression
  app.use(helmet());
  app.use(compression());
  app.use(cookieParser());

  // CORS configuration (supports comma-separated FRONTEND_URL for production + previews)
  const rawOrigins = process.env.FRONTEND_URL || 'http://localhost:3000';
  const configuredOrigins = rawOrigins
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  const allowedOrigins =
    process.env.NODE_ENV === 'production'
      ? configuredOrigins
      : Array.from(
          new Set([
            ...configuredOrigins,
            'http://localhost:3000',
            'http://localhost:3001',
            'http://localhost:5173',
          ]),
        );

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
  });

  // Base API path
  app.setGlobalPrefix('api/v1');

  // Global pipes, filters & interceptors
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(
    new RequestIdInterceptor(),
    new LoggingInterceptor(),
  );

  // OpenAPI / Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('TravelPilot Backend API')
    .setDescription(
      'Private AI Travel Sales & Operations Management System API for authorized staff',
    )
    .setVersion('1.0')
    .addTag('Auth', 'Staff authentication and session management')
    .addTag('Staff', 'Staff user management (Admin only)')
    .addTag('Agency Settings', 'Agency branding and configuration defaults')
    .addTag('Packages', 'Tour package catalog management')
    .addTag('Leads', 'Customer CRM leads and notes')
    .addTag('Follow-Ups', 'Manual follow-up task management')
    .addTag(
      'Quotations',
      'Server-authoritative quotation engine and branded PDF export',
    )
    .addTag('AI', 'Grounded AI advisory assistant for draft responses')
    .addTag('Dashboard', 'Operational metrics and lead funnel analytics')
    .addTag('Audit', 'Audit trail for sensitive actions')
    .addTag('Countries', 'Destination country management for Visa & Immigration')
    .addTag(
      'Visa Services',
      'Visa & Immigration service offerings and requirements',
    )
    .addTag(
      'Visa Inquiries',
      'Public visa consultation inquiries linked to Lead CRM',
    )
    .addCookieAuth('access_token')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
}

export async function createConfiguredApp(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule);
  configureApp(app);
  return app;
}
