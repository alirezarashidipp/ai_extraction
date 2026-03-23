import yaml
import logging
import sys
from llm_client import StructuredLLMClient
from schemas import JiraAnalysis

# Production-grade logging configuration
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

def execute_jira_extraction(description: str):
    """
    Executes extraction with local logic injection.
    Configured for flat prompts.yaml structure (no v3 nesting).
    """
    # 1. Load system prompt from flat YAML structure
    try:
        with open("prompts.yaml", "r") as f:
            config = yaml.safe_load(f)
        
        # Directly accessing the root key
        system_instruction = config.get("main_prompt")
        
        if not system_instruction:
            raise KeyError("'main_prompt' not found in the root of prompts.yaml")
            
        logger.info("System prompt loaded successfully.")
    except Exception as e:
        logger.error(f"Configuration Loading Failed: {e}")
        return None

    # 2. Initialize Client
    client = StructuredLLMClient()

    try:
        # 3. LLM Query - Focused strictly on extraction
        analysis_result = client.query(
            system_prompt=system_instruction,
            user_prompt=description,
            response_model=JiraAnalysis
        )

        # 4. Local Injection: org_text (Zero Token Cost)
        analysis_result.org_text = description

        # 5. Local Logic: agile_standard (100% Deterministic)
        # Calculates based on the presence of Who, What, Why, and AC
        analysis_result.agile_standard = all([
            analysis_result.who.identified,
            analysis_result.what.identified,
            analysis_result.why.identified,
            analysis_result.ac_defined.presence_ac
        ])
        
        logger.info("Analysis and local post-processing completed.")

        # 6. Final Output
        print("\n" + "="*60)
        print("FINAL JIRA METADATA (LOCAL LOGIC APPLIED)")
        print("="*60)
        print(analysis_result.model_dump_json(indent=2))
        
        return analysis_result

    except Exception as e:
        logger.error(f"Pipeline Execution Failed: {str(e)}")
        return None

if __name__ == "__main__":
    test_input = (
        "As a Tfx team, we want to add a new column in the Project class, "
        "so that the application can store and manage additional data "
        "related to the project. (Delivery Yes/No)."
    )

    execute_jira_extraction(test_input)
