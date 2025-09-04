import os
from flask import Flask, request, Response

# Before we can import, we need to ensure the generated code exists.
# In a real run, generate_proto.sh would be run first.
try:
    from schemas_generated import ai_comms_pb2
except ImportError:
    print("ERROR: Protobuf schemas not generated. Please run generate_proto.sh")
    exit(1)

app = Flask(__name__)

@app.route('/decide', methods=['POST'])
def decide():
    """
    Receives a serialized AIDecisionRequest, chooses a candidate,
    and returns a serialized AIDecisionResponse.
    """
    # 1. Deserialize the request from the OCaml engine
    decision_request = ai_comms_pb2.AIDecisionRequest()
    decision_request.ParseFromString(request.data)

    print(f"Received decision request for NPC: {decision_request.npc_id}")
    print(f"Traits: {list(decision_request.traits)}")
    print(f"Inventory: {dict(decision_request.inventory)}")
    print(f"Prompt Template: {decision_request.decision_prompt}")
    print(f"Candidates:")
    for i, candidate in enumerate(decision_request.candidates):
        print(f"  {i+1}. {candidate.op_name}: {candidate.description}")

    # 2. **AI LOGIC PLACEHOLDER**
    # For now, we are not calling an LLM. We will simply and deterministically
    # choose the first candidate to prove the communication loop works.
    # In a future phase, this is where the LLM call will happen.
    
    if not decision_request.candidates:
        # Handle the case of no candidates to avoid an error
        chosen_op = ai_comms_pb2.CandidateOp(op_name="Idle", description="No actions available.")
        rationale = "No valid candidates were provided by the engine."
    else:
        chosen_op = decision_request.candidates[0]
        rationale = "Placeholder logic: chose the first available option."
    
    print(f"Chosen action: {chosen_op.op_name}")

    # 3. Construct and serialize the response
    decision_response = ai_comms_pb2.AIDecisionResponse(
        chosen_op=chosen_op,
        rationale=rationale
    )

    serialized_response = decision_response.SerializeToString()

    return Response(serialized_response, content_type='application/protobuf')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
