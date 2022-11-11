/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

pragma solidity ^0.8.9;
pragma abicoder v2;

contract AudioChat  {
    event handleNewAudioChat(
    bytes32 audio_event_id,
    uint256 start_at,
    uint256 created_at,
    string cid_metadata,
    stateOptions current_state,
    bool is_indexed
    );
    event handleAudioChatChangedState(bytes32 audio_event_id, stateOptions new_state);
    event handleUpdateMetadataCID(bytes32 audio_event_id, string new_cid);
    event handleEventUpdated(
    bytes32 audio_event_id,
    uint256 start_at,
    uint256 created_at,
    string cid_metadata,
    stateOptions current_state,
    bool is_indexed
    );
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
    }


bytes32[] private _owned_ids;
bytes32[] state_live;
bytes32[] state_canceled;
bytes32[] state_planned;
bytes32[] state_ready;
bytes32[] state_finished;
mapping(bytes32 => CreateAudioChat) public id_to_audio_chat; 
mapping(address => bytes32[]) public address_to_audio_chat;
//state will be passed as a string an event is gonna be emitted (handleaudio_chatchangedState)
function _getStateIndex(bytes32 chat_id,bytes32[] storage arr) view private returns (uint256) {
    for (uint256 i = 0; i < arr.length; i++){
        if (arr[i] == chat_id){
            return i;
        }
    }
}
function _getAddressIndex(bytes32 our_id, address creator) view private returns (uint creator_index) {
    bytes32[] storage list_of_addresses = address_to_audio_chat[creator];
    for (uint256 i = 0; i < list_of_addresses.length; i++){
        if (list_of_addresses[i] == our_id){
            return i;
        }
    }
    return list_of_addresses.length + 1;
}



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
            start_at,
            created_at
        )
    );
    require(id_to_audio_chat[audio_event_id].exists == false, "ALREADY REGISTERED");
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
    if (start_at > created_at){
        state_planned.push(audio_event_id);
    }
    else {
        state_ready.push(audio_event_id);
    }
    address_to_audio_chat[creator].push(audio_event_id);
    _owned_ids.push(audio_event_id);
    id_to_audio_chat[audio_event_id] = CreateAudioChat(
        audio_event_id,
        created_at,
        cid_metadata,
        current_state,
        is_indexed,
        creator,
        start_at,
        true
    );    
    emit handleNewAudioChat(
        audio_event_id,
        start_at,
        created_at,
        cid_metadata,
        current_state,
        is_indexed
    );
}


function _updateStateArrays(stateOptions new_state ,bytes32 audio_id) private {
    if (stateOptions.PLANNED == new_state){
        state_planned.push(audio_id);
    }
    else if (stateOptions.LIVE == new_state) {
        state_live.push(audio_id);

    }
    else if (stateOptions.CANCELED == new_state) {
        state_canceled.push(audio_id);
    }
    else if (stateOptions.READY == new_state) {
        state_ready.push(audio_id);
    }
}

function changeState(stateOptions new_changed_state, bytes32 audio_chat_id) public {
    CreateAudioChat storage old_audio_chat_state = id_to_audio_chat[audio_chat_id];
    //PLANNED, LIVE, CANCELED, READY, FINISHED
    //_removeFromStateArrays(old_audio_chat_state.state, old_audio_chat_state.state_index);
    require(id_to_audio_chat[audio_chat_id].creator == msg.sender, "Not the owner of this chat");
    require(old_audio_chat_state.state != new_changed_state, "The changed status cannot be the same as the old one");
    if (stateOptions.PLANNED == old_audio_chat_state.state){
        state_planned[_getStateIndex(audio_chat_id ,state_planned)] = state_planned[state_planned.length - 1];
        state_planned.pop();
    }
    else if (stateOptions.LIVE == old_audio_chat_state.state) {
        state_live[_getStateIndex(audio_chat_id ,state_live)] = state_live[state_live.length - 1];
        state_live.pop();
    }
    else if (stateOptions.CANCELED == old_audio_chat_state.state) {
        state_canceled[_getStateIndex(audio_chat_id ,state_canceled)] = state_canceled[state_canceled.length - 1];
        state_canceled.pop();
    }
    else if (stateOptions.READY == old_audio_chat_state.state) {
        state_ready[_getStateIndex(audio_chat_id ,state_ready) ] = state_ready[state_ready.length - 1];
        state_ready.pop();
    }
    _updateStateArrays(new_changed_state, audio_chat_id);
    id_to_audio_chat[audio_chat_id].state = new_changed_state;

    emit handleAudioChatChangedState(audio_chat_id, new_changed_state);
}

function getAudioChatById(bytes32 id) public view returns ( bytes32 audio_event_id,
        uint256 created_at,
        uint256 start_at,
        string memory cid_metadata,
        stateOptions state,
        address creator,
        bool is_indexed
        ) {
    return (id_to_audio_chat[id].audio_event_id, 
    id_to_audio_chat[id].created_at,
    id_to_audio_chat[id].start_at,
    id_to_audio_chat[id].cid_metadata,
    id_to_audio_chat[id].state,
    id_to_audio_chat[id].creator,
    id_to_audio_chat[id].is_indexed
    );
}
function getAllOwnedIds() public view returns (bytes32[] memory) {
    return _owned_ids;
}
function getAllChats() public view returns (CreateAudioChat[] memory) {
    CreateAudioChat[] memory our_audio_chats = new CreateAudioChat[](_owned_ids.length);
    for (uint256 i; _owned_ids.length > i; i++){
        our_audio_chats[i] = id_to_audio_chat[_owned_ids[i]];
    }
    return our_audio_chats;
}

function getAudioChatsByAdress(address creator) public view  returns(CreateAudioChat[] memory){
        uint256 length_of_array = address_to_audio_chat[creator].length;
        CreateAudioChat[] memory our_audio_chats = new CreateAudioChat[](length_of_array);
        for (uint256 i; length_of_array > i; i++ ){
            our_audio_chats[i] = id_to_audio_chat[address_to_audio_chat[creator][i]];
        }
        return our_audio_chats;
}

function getStateArray(stateOptions state) private view returns(bytes32[] memory){
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

function getAudioChatsByState(stateOptions[] memory options) public view returns(CreateAudioChat[] memory){
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


function deleteAudioChat(bytes32 audio_chat_id) public {
    //PLANNED, LIVE, CANCELED, READY, FINISHED
    require(id_to_audio_chat[audio_chat_id].creator == msg.sender, "Not the owner of this chat");

    require(id_to_audio_chat[audio_chat_id].exists == true, "This chat does not exist anymore");
    CreateAudioChat storage old_audio_chat_state = id_to_audio_chat[audio_chat_id];
    //PLANNED, LIVE, CANCELED, READY, FINISHED
    //_removeFromStateArrays(old_audio_chat_state.state, old_audio_chat_state.state_index);
    if (stateOptions.PLANNED == old_audio_chat_state.state){
        state_planned[_getStateIndex(audio_chat_id ,state_planned)] = state_planned[state_planned.length - 1];
        state_planned.pop();
    }
    else if (stateOptions.LIVE == old_audio_chat_state.state) {
        state_live[_getStateIndex(audio_chat_id ,state_live) ] = state_live[state_live.length - 1];
        state_live.pop();
    }
    else if (stateOptions.CANCELED == old_audio_chat_state.state) {
        state_canceled[_getStateIndex(audio_chat_id ,state_canceled)] = state_canceled[state_canceled.length - 1];
        state_canceled.pop();
    }
    else if (stateOptions.READY == old_audio_chat_state.state) {
        state_ready[_getStateIndex(audio_chat_id ,state_ready) ] = state_ready[state_ready.length - 1];
        state_ready.pop();
    }
    id_to_audio_chat[audio_chat_id].exists = false;
    _owned_ids.pop();
    uint256 chats_length = address_to_audio_chat[old_audio_chat_state.creator].length - 1;
    address_to_audio_chat[old_audio_chat_state.creator][_getAddressIndex(audio_chat_id, old_audio_chat_state.creator)] = 
    address_to_audio_chat[old_audio_chat_state.creator][chats_length];
    address_to_audio_chat[id_to_audio_chat[audio_chat_id].creator].pop();
    delete id_to_audio_chat[audio_chat_id];
}

function updateAudioChat(bytes32 audio_event_id, string memory new_cid, uint256 start_at, bool is_indexed) public {
    CreateAudioChat storage our_audio_chat = id_to_audio_chat[audio_event_id];
    require(id_to_audio_chat[audio_event_id].creator == msg.sender, "Not the owner of this chat");

    require(start_at >= our_audio_chat.created_at, 'created_at cannot be greater than start_at');


    if (keccak256(abi.encodePacked(our_audio_chat.cid_metadata)) != keccak256(abi.encodePacked(new_cid))){
        id_to_audio_chat[audio_event_id].cid_metadata = new_cid;
    }
    if (our_audio_chat.start_at != start_at){
        id_to_audio_chat[audio_event_id].start_at = start_at;
    }
    if (our_audio_chat.is_indexed != is_indexed){
        id_to_audio_chat[audio_event_id].is_indexed = is_indexed;
    }
    emit handleEventUpdated(
        audio_event_id,
        start_at,
        our_audio_chat.created_at,
        new_cid,
        our_audio_chat.state,
        is_indexed        
    );

}
}