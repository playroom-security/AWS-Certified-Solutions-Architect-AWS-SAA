# Project 2.2 – Serverless Event-Driven Pipeline

**Domain:** Design Resilient Architectures  
**Difficulty:** ⭐⭐⭐  
**Estimated Time:** 4–5 hours  
**Approx Cost:** Free Tier eligible (Lambda, SQS, SNS all have generous free tiers)

---

## 🎯 What You'll Build

A fully serverless, event-driven order processing pipeline:
- Orders submitted to an SQS queue (decoupled, buffered)
- Lambda processes orders from the queue
- SNS fan-out for notifications (email + another queue)
- EventBridge for scheduled batch jobs and cross-service events
- Dead Letter Queue (DLQ) for failed message handling
- Step Functions for multi-step order workflow

---

## 🏗️ Architecture Overview

```
Order Submission (API Gateway or CLI)
          │
          ▼
  SQS: OrderQueue (Standard)
  ├── Visibility timeout: 30s
  ├── Message retention: 4 days
  └── DLQ: OrderDLQ (after 3 failures)
          │
          ▼
  Lambda: ProcessOrder
  ├── Reads batch of 10 messages from SQS
  ├── Validates order data
  ├── Writes to DynamoDB: Orders table
  └── Publishes to SNS: OrderEvents topic
          │
          ├──► SQS: EmailQueue → Lambda: SendEmail
          │         (customer confirmation)
          │
          └──► SQS: InventoryQueue → Lambda: UpdateInventory
                    (inventory management)

  EventBridge (Scheduler)
  └── Every day at 6 AM → Lambda: GenerateDailyReport

  Step Functions: OrderFulfillmentWorkflow
  └── ValidateOrder → ChargePayment → UpdateInventory → SendConfirmation
```

---

## 📋 What You'll Learn

- SQS: Standard vs FIFO queues, visibility timeout, DLQ
- SNS fan-out pattern (one message → multiple subscribers)
- Lambda event source mappings (SQS trigger)
- EventBridge rules and scheduled expressions
- AWS Step Functions for complex workflows
- Loose coupling: services communicate via queues, not direct calls

---

## 🛠️ Step-by-Step Instructions

### Phase 1: Set Up SQS Queues (30 min)
1. Deploy `cloudformation/sqs-queues.yaml`
2. Creates: `OrderQueue`, `EmailQueue`, `InventoryQueue`, `OrderDLQ`
3. In SQS console, explore queue attributes:
   - Visibility timeout (30s): message invisible while being processed
   - Message retention (4 days): how long messages persist unprocessed
   - Max receive count (3): moves to DLQ after 3 failed processing attempts
4. Manually send a test message: `aws sqs send-message --queue-url QUEUE_URL --message-body '{"orderId":"123","item":"book"}'`

### Phase 2: Create SNS Topic with Fan-out (20 min)
1. Create SNS topic: `OrderEvents`
2. Subscribe `EmailQueue` to the topic
3. Subscribe `InventoryQueue` to the topic
4. Subscribe your email address (confirm the subscription)
5. Publish a test message → verify it arrives in both SQS queues AND your email

### Phase 3: Deploy Lambda Functions (1 hour)
1. Deploy `cloudformation/lambda-functions.yaml`
2. Creates 4 Lambda functions with appropriate IAM roles:
   - `ProcessOrder`: SQS trigger from OrderQueue, writes to DynamoDB, publishes to SNS
   - `SendEmail`: SQS trigger from EmailQueue
   - `UpdateInventory`: SQS trigger from InventoryQueue
   - `GenerateDailyReport`: no trigger (EventBridge invokes it)
3. Test `ProcessOrder` directly with a test event from `events/test-order.json`
4. Send a message to `OrderQueue` — watch all downstream Lambdas trigger

### Phase 4: Configure EventBridge (20 min)
1. Create an EventBridge rule: schedule `cron(0 6 * * ? *)` (6 AM daily)
2. Target: `GenerateDailyReport` Lambda
3. Also create a pattern-based rule: trigger when a DynamoDB item is created in Orders table
4. Test: manually invoke the rule from EventBridge console

### Phase 5: Build a Step Functions Workflow (1 hour)
1. Deploy `cloudformation/step-functions.yaml`
2. Creates an `OrderFulfillmentWorkflow` state machine
3. Review the state machine definition (ASL JSON) in `stepfunctions/order-workflow.json`
4. Start an execution from the console with input from `events/step-functions-input.json`
5. Observe the visual workflow execution — see which states pass/fail
6. Introduce an error in one Lambda → see retry logic and error catching in action

### Phase 6: Test the DLQ (20 min)
1. Modify `ProcessOrder` Lambda to throw an error intentionally
2. Send 3 messages to `OrderQueue`
3. After 3 failures each, messages should appear in `OrderDLQ`
4. Monitor DLQ depth in CloudWatch
5. Restore Lambda and reprocess DLQ messages

---

## 📄 Files in This Project

| File | Purpose |
|------|---------|
| `cloudformation/sqs-queues.yaml` | SQS queues with DLQ config |
| `cloudformation/lambda-functions.yaml` | All 4 Lambda functions + IAM roles |
| `cloudformation/step-functions.yaml` | Step Functions state machine |
| `lambda/process-order.py` | Lambda: processes orders, writes DynamoDB, publishes SNS |
| `lambda/send-email.py` | Lambda: mock email sender |
| `lambda/update-inventory.py` | Lambda: mock inventory update |
| `lambda/daily-report.py` | Lambda: EventBridge scheduled report |
| `stepfunctions/order-workflow.json` | ASL definition for Step Functions |
| `events/test-order.json` | Lambda test event payload |
| `events/step-functions-input.json` | Step Functions execution input |

---

## 🧹 Cleanup

1. Delete CloudFormation stacks
2. Delete SNS topic and subscriptions
3. Delete DynamoDB table

---

## 📝 Exam Topics Covered

- ✅ SQS Standard vs FIFO, visibility timeout, DLQ
- ✅ SNS fan-out pattern
- ✅ Lambda event source mappings (SQS trigger)
- ✅ EventBridge rules and schedules
- ✅ AWS Step Functions
- ✅ Loose coupling and event-driven architecture
- ✅ Serverless patterns and stateless workloads
