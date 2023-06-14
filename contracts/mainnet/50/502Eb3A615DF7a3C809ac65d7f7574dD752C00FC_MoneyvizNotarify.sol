// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Notarization registry made for Moneyviz srl
 * @notice Use this contract to notarify information
 * @author Alessandro Morandi <[email protected]>
 */
contract MoneyvizNotarify {

    struct NotarizationDoc {
        string reasonid;
        address sender;
        string hash;
        string tag;
        uint256 timestamp;
    }

    mapping(uint256 => NotarizationDoc) internal docHistory;
    mapping(address => uint256[]) internal senderDocs;
    mapping(string => uint256) internal hashDocs;
    uint256 public DocCount = 0;

    event CreatedNewNotarizationDocEvent(
        string  indexed reasonid,
        address indexed sender,
        string  indexed tag,
        string  hash
    );

    function createNotarizationDoc(
        string memory _reasonid,
        string memory _hash,
        string memory _tag
    ) public {
        DocCount++;

        docHistory[DocCount] = NotarizationDoc(
            _reasonid,
            msg.sender,
            _hash,
            _tag,
            block.timestamp
        );
        senderDocs[msg.sender].push(DocCount);
        hashDocs[_hash] = (DocCount);
        emit CreatedNewNotarizationDocEvent(
            _reasonid,
            msg.sender,
            _hash,
            _tag
        );
    }

    function getDocCount() public view returns (uint256) {
        return DocCount;
    }
    function getDocsByAddress(address _sender) public view returns (uint256[] memory) {
        return senderDocs[_sender];
    }

    function getDocById(uint256 _index) public view returns (NotarizationDoc memory) {
        require(_index <= DocCount, "Index is not valid. must be < max doc history array lenght");
        NotarizationDoc memory doc = docHistory[_index];
        return doc;
    }

    function getDocByHash(string  calldata _hash) public view returns (uint256 ) {
        return hashDocs[_hash];
    }
}