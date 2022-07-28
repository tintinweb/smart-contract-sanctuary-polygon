/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

contract SneakyChat{
    struct Message{
        address sender;
        uint time;
        string content;
    }

    Message[] public messagesArray;
    mapping(address=>uint[]) public ownerIndexs;

    function writeMessage(string memory _msgContent) public{
        ownerIndexs[msg.sender].push(messagesArray.length);
        messagesArray.push(Message(msg.sender, block.timestamp, _msgContent));
    }

    function deleteAllMessagesOfSender() public{
        for(uint16 i = 0; i < ownerIndexs[msg.sender].length; i++){
            messagesArray[ownerIndexs[msg.sender][i]].content = "";
        }
        //delete ownerIndexs[msg.sender]; ?- ESTA FUNCIÓN COSTARÍA ETH? NO ESCRIBE, SOLO BORRA DE LAS STATES VARIABLES
    }

    function deleteMessageAtIndex(uint16 _indexToDel) public{
        require(msg.sender == messagesArray[_indexToDel].sender);
        messagesArray[_indexToDel].content = "";
    }

    function getAllMessages() public view returns (Message[] memory){
        return messagesArray;
    }

    function getAllMessagesOfUser(address _adrFilter) public view returns (Message[] memory){
        Message[] memory userMessages = new Message[](ownerIndexs[_adrFilter].length);
        for(uint16 i = 0; i < ownerIndexs[_adrFilter].length; i++){
            userMessages[i] = messagesArray[ownerIndexs[_adrFilter][i]];
        }
        return userMessages;
    }

    function getLastHundredMessages() public view returns (Message[] memory){
        if(messagesArray.length < 100){
            return messagesArray;
        } else {
            Message[] memory lastMessages = new Message[](100);
            for(uint8 i=100; i>0; i--){
                lastMessages[100-i] = messagesArray[messagesArray.length-i];
            }
            return lastMessages;
        }
    }
}