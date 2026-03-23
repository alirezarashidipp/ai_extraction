import yaml
import logging
import sys
from llm_client import StructuredLLMClient
from schemas import JiraAnalysis

# Configure logging for production traceability
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

def execute_jira_extraction(description: str):
    """
    Orchestrates the flow: Load prompts -> Initialize Client -> Query LLM -> Validate Schema.
    """
    # 1. Load prompts from external YAML source
    try:
        with open("prompts.yaml", "r") as f:
            config = yaml.safe_load(f)
        
        system_instruction = config["v3"]["main_prompt"]
        logger.info("Prompts loaded successfully from prompts.yaml")
    except (FileNotFoundError, KeyError) as e:
        logger.error(f"Configuration Error: Could not find prompts. {e}")
        return None

    # 2. Initialize the Structured LLM Client
    # Uses default enterprise parameters defined in llm_client.py
    client = StructuredLLMClient()

    logger.info("Initiating LLM request for structured metadata extraction...")

    try:
        # 3. Call the query method with the Pydantic response model
        # This returns a validated JiraAnalysis object
        analysis_result = client.query(
            system_prompt=system_instruction,
            user_prompt=description,
            response_model=JiraAnalysis
        )

        # 4. Output the validated data
        logger.info("Extraction successful. Validated JSON output generated.")
        
        print("\n" + "="*60)
        print("PRODUCTION JIRA ANALYSIS OUTPUT")
        print("="*60)
        print(analysis_result.model_dump_json(indent=2))
        
        return analysis_result

    except Exception as e:
        logger.error(f"Execution Pipeline Failed: {str(e)}")
        return None

if __name__ == "__main__":
    # Test input representing a standard Jira Story
    test_description = (
        "As a Tfx team, we want to add a new column in the Project class, "
        "so that the application can store and manage additional data "
        "related to the project. (Delivery Yes/No)."
    )

    execute_jira_extraction(test_description)
