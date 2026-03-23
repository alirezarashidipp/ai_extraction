import yaml
import logging
import sys
from llm_client import StructuredLLMClient
from schemas import JiraAnalysis

# Standard production logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

def execute_jira_extraction(description: str):
    """
    Executes the extraction pipeline with local attribute injection to save tokens.
    """
    # 1. Load system prompt from YAML
    try:
        with open("prompts.yaml", "r") as f:
            config = yaml.safe_load(f)
        
        system_instruction = config["v3"]["main_prompt"]
        logger.info("Configuration and prompts loaded.")
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        return None

    # 2. Initialize the client (using default enterprise parameters)
    client = StructuredLLMClient()

    logger.info("Requesting structured analysis from LLM...")

    try:
        # 3. Perform LLM Query
        # Note: The LLM will NOT generate 'org_text' because it has a default value in Schema
        analysis_result = client.query(
            system_prompt=system_instruction,
            user_prompt=description,
            response_model=JiraAnalysis
        )

        # 4. Local Injection (Zero Token Cost)
        # Manually populating the field that we excluded from the LLM prompt
        analysis_result.org_text = description
        
        logger.info("Analysis complete. Input reflected locally to optimize cost.")

        # 5. Output the result
        print("\n" + "="*60)
        print("OPTIMIZED JIRA ANALYSIS OUTPUT")
        print("="*60)
        print(analysis_result.model_dump_json(indent=2))
        
        return analysis_result

    except Exception as e:
        logger.error(f"Pipeline execution failed: {str(e)}")
        return None

if __name__ == "__main__":
    # Test case
    test_input = (
        "As a Tfx team, we want to add a new column in the Project class, "
        "so that the application can store and manage additional data "
        "related to the project. (Delivery Yes/No)."
    )

    execute_jira_extraction(test_input)
