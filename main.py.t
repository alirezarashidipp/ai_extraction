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
    Executes the extraction pipeline with local logic for agile_standard 
    and org_text to ensure 100% accuracy and zero extra token cost.
    """
    # 1. Load system prompt from YAML
    try:
        with open("prompts.yaml", "r") as f:
            config = yaml.safe_load(f)
        
        # Accessing the main_prompt from the v3 or root level as defined in your yaml
        system_instruction = config.get("v3", {}).get("main_prompt") or config.get("main_prompt")
        logger.info("Configuration and prompts loaded.")
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        return None

    # 2. Initialize the client
    client = StructuredLLMClient()

    logger.info("Requesting structured analysis from LLM...")

    try:
        # 3. Perform LLM Query
        # The LLM focuses only on extraction (Who, What, Why, AC, Reasoning, Questions)
        analysis_result = client.query(
            system_prompt=system_instruction,
            user_prompt=description,
            response_model=JiraAnalysis
        )

        # 4. Local Injection of org_text (Zero Token Cost)
        analysis_result.org_text = description

        # 5. Local Calculation of agile_standard (Zero Token Cost & 100% Accuracy)
        # Standard: Who, What, Why are identified AND Acceptance Criteria is present
        analysis_result.agile_standard = all([
            analysis_result.who.identified,
            analysis_result.what.identified,
            analysis_result.why.identified,
            analysis_result.ac_defined.presence_ac
        ])
        
        logger.info("Post-processing complete: Input reflected and Agile standard calculated locally.")

        # 6. Output the result
        print("\n" + "="*60)
        print("PRODUCTION-READY JIRA ANALYSIS (OPTIMIZED)")
        print("="*60)
        print(analysis_result.model_dump_json(indent=2))
        
        return analysis_result

    except Exception as e:
        logger.error(f"Pipeline execution failed: {str(e)}")
        return None

if __name__ == "__main__":
    # Test case representing a requirement
    test_input = (
        "As a Tfx team, we want to add a new column in the Project class, "
        "so that the application can store and manage additional data "
        "related to the project. (Delivery Yes/No)."
    )

    execute_jira_extraction(test_input)
