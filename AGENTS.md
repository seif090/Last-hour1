# Commands

## Local Development
```bash
docker compose up -d postgres redis
cd backend && npm run start:dev
```

## Flutter
```bash
cd flutter/customer_app && flutter run
cd flutter/merchant_app && flutter run
```

## Lint & Typecheck
```bash
cd backend && npm run lint && npm run typecheck
cd flutter/customer_app && flutter analyze
cd flutter/merchant_app && flutter analyze
```

## Database
```bash
cd backend && npx prisma migrate dev
cd backend && npx prisma db seed
```

## Test
```bash
cd backend && npm test
cd backend && npm run test:e2e
```

## Deployment
```bash
cd iac && terraform plan -var-file=terraform.tfvars
```
