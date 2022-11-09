/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

pragma solidity ^0.8.9;
pragma abicoder v2;
contract AudioChat {
    event handleNewAudioChat(
    bytes32 audio_event_id,
    uint256 start_at,
    uint256 created_at,
    string cid_metadata,
    stateOptions current_state
    );
    event handleAudioChatStateChanged(bytes32 audio_event_id, stateOptions new_state);
    event handleUpdateMetadataCID(bytes32 audio_event_id, string new_cid);
    enum stateOptions{ PLANNED, LIVE, CANCELED, READY, FINISHED}

    struct CreateAudioChat {
        bytes32 audio_event_id;
        uint256 created_at;
        string cid_metadata;
        stateOptions state;
        bool is_indexed;
        address creator;
        uint256 start_at;
        bool exists;
        uint256 id_index;
        uint256 state_index;
        uint256 address_index;
    }


bytes32[] private _owned_ids;
bytes32[] state_live;
bytes32[] state_canceled;
bytes32[] state_planned;
bytes32[] state_ready;
bytes32[] state_finished;
mapping(bytes32 => CreateAudioChat) public id_to_audio_chat; 
mapping(address => bytes32[]) public address_to_audio_chat;
//state will be passed as a string an event is gonna be emitted (handleaudio_chatstateChanged)

function createNewAudioChat(
    uint256 start_at,
    uint256 created_at,
    string calldata cid_metadata,
    address creator,
    bool is_indexed
) external {
    
    bytes32 audio_event_id = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            start_at
        )
    );
    require(id_to_audio_chat[audio_event_id].start_at == 0, "ALREADY REGISTERED");
    require(start_at >= created_at, 'created_at cannot be greater than start_at');
    stateOptions current_state;
    uint256 new_list_address_index;
    if (address_to_audio_chat[creator].length == 0){
        new_list_address_index = 0;
    }
    else {
        new_list_address_index = address_to_audio_chat[creator].length - 1;
    }

    if (start_at > created_at){
        current_state = stateOptions.PLANNED;
    }
    else {
        current_state = stateOptions.READY;
    }
    require(id_to_audio_chat[audio_event_id].start_at == 0, "ALREADY REGISTERED");
    uint256 state_index;
    uint256 address_index;
    if (start_at < created_at){
        state_planned.push(audio_event_id);
        state_index = state_planned.length - 1;
    }
    else {
        state_ready.push(audio_event_id);
        state_index = state_ready.length - 1;
    }
    address_to_audio_chat[creator].push(audio_event_id);
    address_index = address_to_audio_chat[creator].length- 1;
    _owned_ids.push(audio_event_id);
    uint256 id_index = _owned_ids.length - 1;
    id_to_audio_chat[audio_event_id] = CreateAudioChat(
        audio_event_id,
        created_at,
        cid_metadata,
        current_state,
        is_indexed,
        creator,
        start_at,
        true,
        id_index,
        state_index,
        address_index
    );
    _owned_ids.push(audio_event_id);
    
    emit handleNewAudioChat(
        audio_event_id,
        start_at,
        created_at,
        cid_metadata,
        current_state
    );
}

function removeFromStateArrays(stateOptions old_state, uint256 index) private {
    if (stateOptions.PLANNED == old_state){
        state_planned[index];
        state_planned[index] = state_planned[state_planned.length - 1];
        state_planned.pop();
    }
    else if (stateOptions.LIVE == old_state) {
        state_live[index] = state_live[state_live.length - 1];
        state_live.pop();
    }
    else if (stateOptions.CANCELED == old_state) {
        state_canceled[index] = state_canceled[state_canceled.length - 1];
        state_canceled.pop();
    }
    else if (stateOptions.READY == old_state) {
        state_ready[index] = state_ready[state_ready.length - 1];
        state_ready.pop();
    }
}

function updateStateArrays(stateOptions new_state, bytes32 audio_id) private {
    uint256 new_state_index;
    if (stateOptions.PLANNED == new_state){
        state_planned.push(audio_id);
        new_state_index = state_planned.length - 1;
    }
    else if (stateOptions.LIVE == new_state) {
        state_live.push(audio_id);
        new_state_index = state_live.length - 1;
    }
    else if (stateOptions.CANCELED == new_state) {
        state_canceled.push(audio_id);
        new_state_index = state_canceled.length - 1;
    }
    else if (stateOptions.READY == new_state) {
        state_ready.push(audio_id);
        new_state_index = state_ready.length - 1;
    }
    id_to_audio_chat[audio_id].state_index = new_state_index;
}

function stateChanged(stateOptions new_changed_state, bytes32 audio_chat_id) public {
    CreateAudioChat storage old_audio_chat_state = id_to_audio_chat[audio_chat_id];
    //PLANNED, LIVE, CANCELED, READY, FINISHED
    removeFromStateArrays(old_audio_chat_state.state, old_audio_chat_state.state_index);
    updateStateArrays(new_changed_state ,audio_chat_id);
    id_to_audio_chat[audio_chat_id].state = new_changed_state;

    emit handleAudioChatStateChanged(audio_chat_id, new_changed_state);
}

function getAudioChatById(bytes32 id) public view returns ( bytes32 audio_event_id,
        uint256 created_at,
        uint256 start_at,
        string memory cid_metadata,
        stateOptions state,
        address creator
        ) {
    return (id_to_audio_chat[id].audio_event_id, 
    id_to_audio_chat[id].created_at,
    id_to_audio_chat[id].start_at,
    id_to_audio_chat[id].cid_metadata,
    id_to_audio_chat[id].state,
    id_to_audio_chat[id].creator
    );
}
function getAllOwnedIds() public view virtual returns (bytes32[] memory) {
    return _owned_ids;
}


function getAudioChatsByAdress(address creator) public view returns(CreateAudioChat[] memory){
        uint256 length_of_array = address_to_audio_chat[creator].length;
        CreateAudioChat[] memory our_audio_chats = new CreateAudioChat[](length_of_array);
        for (uint256 i; length_of_array > i; i++ ){
            our_audio_chats[i] = id_to_audio_chat[address_to_audio_chat[creator][i]];
        }
        return our_audio_chats;
}

function getStateArray(stateOptions state) public returns(bytes32[] memory){
    if (stateOptions.PLANNED == state){
        return state_planned;
    }
    else if (stateOptions.LIVE == state) {
        return state_live;
    }
    else if (stateOptions.CANCELED == state) {
        return state_canceled;
    }
    else if (stateOptions.READY == state) {
        return state_ready;
    }
}

function getAudioChatsByState(stateOptions[] memory options) public returns(CreateAudioChat[] memory){
    uint256 total_size;
    for (uint256 i; options.length > i; i++){
        total_size += getStateArray(options[i]).length;
    }
    CreateAudioChat[] memory audio_chats = new CreateAudioChat[](total_size);
    uint256 count = 0;
    for (uint256 i; options.length > i; i++){
        bytes32[] memory current_audio_chat_arr = getStateArray(options[i]);
        for (uint256 ch; current_audio_chat_arr.length > ch; ch++){
            audio_chats[count] = id_to_audio_chat[current_audio_chat_arr[ch]];
            count++;
        }
    }
    return audio_chats;
}


function deleteTheAudioChat(bytes32 audio_event_id) public {
    //PLANNED, LIVE, CANCELED, READY, FINISHED
    require(id_to_audio_chat[audio_event_id].exists == true);
    id_to_audio_chat[audio_event_id].exists = false;
    removeFromStateArrays(id_to_audio_chat[audio_event_id].state, id_to_audio_chat[audio_event_id].state_index);
    _owned_ids[id_to_audio_chat[audio_event_id].id_index] = _owned_ids[_owned_ids.length - 1];
    _owned_ids.pop();
    address_to_audio_chat[id_to_audio_chat[audio_event_id].creator][id_to_audio_chat[audio_event_id].address_index] = 
    address_to_audio_chat[id_to_audio_chat[audio_event_id].creator][address_to_audio_chat[id_to_audio_chat[audio_event_id].creator].length - 1];
    address_to_audio_chat[id_to_audio_chat[audio_event_id].creator].pop();


}

function updateTheAudioChat(bytes32 audio_event_id, string memory new_cid, uint256 start_at) public {
    CreateAudioChat storage our_audio_chat = id_to_audio_chat[audio_event_id];
    if (keccak256(abi.encodePacked(our_audio_chat.cid_metadata)) != keccak256(abi.encodePacked(new_cid))){
        id_to_audio_chat[audio_event_id].cid_metadata = new_cid;
    }
    if (our_audio_chat.start_at != start_at){
        id_to_audio_chat[audio_event_id].start_at = start_at;
    }
    

}
}