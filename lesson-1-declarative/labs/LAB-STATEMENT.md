# Lab 1: Create a Declarative Financial Advisor Agent

> 🇧🇷 **[Leia em Português (pt-BR)](LAB-STATEMENT.pt-BR.md)**

## Objective

Build a declarative agent in Azure AI Foundry using the `azure-ai-projects` SDK (new Foundry experience). The agent will answer questions about Brazilian and international financial markets without requiring custom code or containers.

## Scenario

Your team needs a quick prototype financial advisor agent for internal testing. The agent should:
- Answer questions about stock prices (B3 and international markets)
- Explain exchange rates
- Provide market summaries
- Respond in Brazilian Portuguese
- Include appropriate disclaimers

Since this is a prototype, you'll use the **declarative pattern** (no custom tools, no containers).

## Learning Outcomes

After completing this lab, you will be able to:
- Create declarative agents using `PromptAgentDefinition`
- Configure system prompts for domain-specific behavior
- Test agents programmatically via SDK
- Modify agents in Foundry Portal without code changes
- Understand the advantages and limitations of declarative agents

## Prerequisites

- [x] Azure AI Foundry project deployed
- [x] GPT-4 model deployed in Foundry
- [x] Azure CLI logged in (`az login`)
- [x] Python 3.10+ with `pip`
- [x] "Azure AI User" role on Foundry project

## Tasks

### Task 1: Set Up Environment (5 minutes)

1. Navigate to the `starter/` directory
2. Create a `.env` file with your Foundry credentials:
   ```
   PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
   MODEL_DEPLOYMENT_NAME=gpt-4.1
   ```
3. Install dependencies:
   ```powershell
   pip install -r requirements.txt
   ```

**Success Criteria**:
- ✅ Dependencies installed without errors
- ✅ `.env` file contains correct endpoint

### Task 2: Create the Agent (15 minutes)

1. Open `create_agent.py` in the `starter/` directory
2. Complete the `create_agent()` function:
   - Import `AIProjectClient` and `PromptAgentDefinition`
   - Authenticate with `DefaultAzureCredential`
   - Create agent with `PromptAgentDefinition`
   - Define system prompt for financial advisor behavior

**Hints**:
- Use `project_client.agents.create_version()` to create agent
- System prompt should specify: domain (finance), language (PT-BR), tone (professional), disclaimers
- Model parameter should reference your deployed model name

3. Run the script:
   ```powershell
   python create_agent.py
   ```

**Success Criteria**:
- ✅ Script outputs agent name, version, and ID
- ✅ No authentication errors
- ✅ Agent visible in Foundry Portal (https://ai.azure.com/)

### Task 3: Create Test Client (20 minutes)

1. Open `test_agent.py` in the `starter/` directory
2. Implement the chat loop:
   - Get OpenAI client from the project
   - Create a conversation for multi-turn chat
   - Send messages via the Responses API with `agent_reference`
   - Handle user input loop

**Hints**:
- Use `project_client.get_openai_client()` to get an OpenAI-compatible client
- Use `openai_client.conversations.create()` to create a conversation context
- Use `openai_client.responses.create(conversation=..., extra_body={"agent": {"name": agent_name, "type": "agent_reference"}}, input=...)` to send messages
- Access the response text via `response.output_text`

3. Run the test client:
   ```powershell
   python test_agent.py
   ```

**Success Criteria**:
- ✅ Client connects to agent successfully
- ✅ Messages are sent and responses received
- ✅ Conversation context is maintained across messages
- ✅ Agent responds in Portuguese with financial knowledge

### Task 4: Test Agent Capabilities (10 minutes)

Test the agent with these questions:
1. "Qual é a cotação da PETR4?"
2. "Como está o câmbio USD/BRL hoje?"
3. "Me dê um resumo do mercado brasileiro"
4. "Explique o que é o Ibovespa"

**Expected Behavior**:
- Agent acknowledges lack of real-time data
- Provides educational information about topics
- Includes disclaimer: "Esta informação é apenas para fins educativos..."
- Responds in Brazilian Portuguese
- Uses appropriate formatting (R$ for BRL values)

**Success Criteria**:
- ✅ Agent responds relevant to each question
- ✅ Disclaimers are included
- ✅ Language and tone are appropriate

### Task 5: Modify Agent in Portal (10 minutes)

1. Navigate to [Azure AI Foundry Portal](https://ai.azure.com/)
2. Select your project → **Agents** → Your agent
3. Click **Edit**
4. Modify the system prompt:
   - Add: "Always start responses with an appropriate emoji related to finance (📈, 📉, 💰, 💹)"
   - Add: "Keep responses to maximum 3 paragraphs"
5. Click **Save** (changes are immediate, no redeployment!)

6. Test again with `test_agent.py`

**Success Criteria**:
- ✅ Agent responses now include emojis
- ✅ Responses are more concise (≤3 paragraphs)
- ✅ Changes applied instantly without redeploying

### Task 6: Add Foundry Catalog Tool (Optional - Advanced, 15 minutes)

**Challenge**: Enhance your agent with Bing Grounding Search tool for real-time data.

1. In Foundry Portal:
   - Go to **Connections** → Add **Bing Search** connection
   - Note the connection name

2. Modify `create_agent.py` to include Bing tool:
   ```python
   from azure.ai.projects.models import (
       BingGroundingAgentTool,
       BingGroundingSearchToolParameters,
   )
   
   bing_connection = project_client.connections.get("bing-connection-name")
   
   agent = project_client.agents.create_version(
       agent_name="fin-market-with-bing",
       definition=PromptAgentDefinition(
           model="gpt-4.1",
           instructions="...",
           tools=[
               BingGroundingAgentTool(
                   bing_grounding=BingGroundingSearchToolParameters(
                       search_configurations=[{
                           "project_connection_id": bing_connection.id
                       }]
                   )
               )
           ],
       ),
   )
   ```

3. Test: Ask for "latest PETR4 stock price"

**Success Criteria**:
- ✅ Agent searches Bing for current data
- ✅ Responses include real-time market information

## Deliverables

- [x] Working `create_agent.py` script
- [x] Working `test_agent.py` client
- [x] Agent visible and testable in Foundry Portal
- [x] Screenshot of successful agent conversation
- [x] (Optional) Enhanced agent with Bing Search tool

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **Agent Creation** | 25 pts | Agent created successfully via SDK |
| **System Prompt Quality** | 20 pts | Appropriate domain knowledge and guidelines |
| **Test Client** | 25 pts | Functional conversation loop with Responses API |
| **Testing** | 15 pts | Tested multiple scenarios, verified behavior |
| **Portal Modification** | 10 pts | Successfully modified and tested changes |
| **Code Quality** | 5 pts | Clean, documented, follows Python conventions |
| **Bonus: Bing Tool** | +10 pts | Successfully integrated Foundry catalog tool |

**Total**: 100 points (+10 bonus)

## Troubleshooting

### "Authentication failed"
- Verify `az login` is successful
- Check `PROJECT_ENDPOINT` in `.env` is correct
- Ensure you have "Azure AI User" role

### "Model deployment not found"
- Check model name matches Foundry deployment (case-sensitive)
- Verify model is deployed in Portal → Models

### "Agent returns generic responses"
- System prompt may be too vague
- Add more specific instructions and examples
- Include domain constraints

## Time Estimate

- Task 1: 5 minutes
- Task 2: 15 minutes
- Task 3: 20 minutes
- Task 4: 10 minutes
- Task 5: 10 minutes
- Task 6: 15 minutes (optional)
- **Total**: 60-75 minutes

## Next Steps

After completing this lab:
- Proceed to **Lab 2** to learn custom tools with MAF
- Compare declarative vs hosted patterns
- Understand when to choose each approach

---

**Difficulty**: Beginner  
**Prerequisites**: Basic Python, Azure fundamentals  
**Estimated Time**: 60 minutes
