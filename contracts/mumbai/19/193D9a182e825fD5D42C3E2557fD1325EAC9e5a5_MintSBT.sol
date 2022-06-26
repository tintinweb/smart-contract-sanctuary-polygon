/**
 *Submitted for verification at polygonscan.com on 2022-06-26
*/

// File: MintSBT_flat.sol


// File: HackHeist/SBT.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SBT {
    string name;
    string symbol;
    address internal SBTowner;
    uint public Supply;
    constructor(string memory _name, string memory _symbol){
        SBTowner = msg.sender;
        name = _name;
        symbol = _symbol;
    }
    
    mapping (uint => address) private sbts;
    mapping (uint => string) private uri;

    function contractOwner() external view returns (address){
        return SBTowner;
    }

    function totalSupply() external view returns (uint){
        return Supply;
    }

    function Name() external view returns(string memory){
        return name;
    }

    function Symbol() external view returns(string memory){
        return symbol;
    }
  
    function _mint(address _to) internal {
        require (sbts[Supply]== address(0), "token already minted");
        require(SBTowner == msg.sender,"Not the owner of this function");
        Supply++;
        sbts[Supply] = _to;
        // uri[Supply] = _uriVal;
    }

    function _revokeAndRetransfer(address _from, address _to, uint _tokenId) internal {
        require(SBTowner == msg.sender, "Cant revoke token");
        require(ownerOf(_from, _tokenId) == true, "Not owner of");
        sbts[_tokenId] = _to;
    }

    function ownerOf(address _addr, uint _tokenId) public view returns (bool){
        if(sbts[_tokenId] == _addr){
            return true;
        }else{
            return false;
        }
    }
}

// File: HackHeist/ERC725.sol

pragma solidity >=0.7.0 <0.9.0;

contract ERC725 {
    address public ContractOwner;
    constructor(){
        ContractOwner = msg.sender;
    }
    mapping(bytes32 => bytes) internal store;

    function setData(bytes32[] memory dataKeys, bytes[] memory dataValues) public {
        require(msg.sender == ContractOwner, "Not permitted");
        require(dataKeys.length == dataValues.length, "Keys length not equal to values length");
        for (uint256 i = 0; i < dataKeys.length; i++) {
            _setData(dataKeys[i], dataValues[i]);
        }
    }
    function setDataSingle(bytes32 dataKey, bytes memory dataValue) public {
        // require(msg.sender == ContractOwner, "Not permitted");
        _setData(dataKey, dataValue);
    }
    function _setData(bytes32 dataKey, bytes memory dataValue) internal {
        store[dataKey] = dataValue;
    }
    function getDataBulk(bytes32[] memory dataKeys) public view returns (bytes[] memory dataValues)
    {
        dataValues = new bytes[](dataKeys.length);
        for (uint256 i = 0; i < dataKeys.length; i++) {
            dataValues[i] = _getData(dataKeys[i]);
        }
        return dataValues;
    }
    function getData(bytes32 dataKey) public view returns (bytes memory dataValue){
        dataValue = _getData(dataKey);
        return dataValue;
    }
    function _getData(bytes32 dataKey) internal view returns (bytes memory dataValue) {
        return store[dataKey];
    }
    function returnContractOwner() public view returns(address){
        return ContractOwner;
    }
}
// File: HackHeist/QuestionQuiz.sol

pragma solidity >=0.7.0 <0.9.0;

contract QuestionQuiz{
    bytes32 salt = bytes32("123123123");
    bytes32 hashedAnswer;
    string public question;
    mapping(address => bool) answered;
    mapping(address => string) answerGiven;
    mapping(address => bool) correctOrNot;
    address public owner;
    constructor(string memory _question, bytes32 _answer){
       question = _question;
       hashedAnswer= _answer;
       owner = msg.sender;
    } 
    function guess(address _addr, string memory _answer) public {
        _guess(_addr, _answer);
    }
    function _guess(address _addr,string memory _answer) private{
        require(answered[_addr] == false,"Already Answered");
        answered[_addr] = true;
        answerGiven[_addr] = _answer;
        if(keccak256(abi.encodePacked(salt,_answer)) == hashedAnswer){
            correctOrNot[_addr] = true;
        }
    }
    function hasAnswered(address _addr) public view returns(bool){
        return answered[_addr];
    }
    function returnOwner() public view returns (address){
        return owner;
    }
    function returnAnswer(address _addr) public view returns(string memory){
        return answerGiven[_addr];
    } 
    function returnAnswerForScore(address _addr) public view returns(bool){
        return correctOrNot[_addr];
    }
    function returnQuestion() public view returns(string memory){
        return question;
    }
}
// File: @openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: HackHeist/Merkle.sol

pragma solidity >=0.7.0 <0.9.0;



contract Merkle{
    bytes32 root;
    address public owner;
    //  constructor(){
    //     owner = msg.sender;
    // }
    event AddedAccount(address indexed acc, bytes32 indexed hsh);
    event RemoveAccount(address indexed acc, bytes32 indexed hsh);
    function updateRoot(bytes32 hash) public {
        require(msg.sender == owner,"Sorry No Access");
        root = hash;
    }
    function returnHash() public view returns(bytes32){
        return root;
    }
    function verify(bytes32[] memory proof,bytes32 leaf) public view returns(bool){
        return MerkleProof.verify(proof, root, leaf);
    }
}

// File: HackHeist/ProctoredQuiz.sol


pragma solidity >=0.7.0 <0.9.0;



contract ProctoredQuiz is Merkle{
    uint public totalQuestions = 0;


    mapping(uint => QuestionQuiz) public quizes;
    mapping(address => uint) public totalScores;

    function createQuiz(string memory _question, bytes32  _hashedanswer) public{
        QuestionQuiz question = new QuestionQuiz(_question,_hashedanswer);
        quizes[totalQuestions] = question;
        totalQuestions++;
    }

    function guessQuiz(uint _index,string memory _answer) public{
        QuestionQuiz q = quizes[_index];
        q.guess(msg.sender,_answer);
    }
    function OwnerOfContract(uint _index) public view returns(address){
         QuestionQuiz q = quizes[_index];
         address own = q.returnOwner();
         return own;
    }
     function calculateTotalScores(address _addr) public {
        require(totalQuestions > 0);
        totalScores[_addr] = 0;
        for(uint i = 0 ; i< totalQuestions; i++){
             QuestionQuiz q = quizes[i];
            if(q.returnAnswerForScore(_addr)){
                totalScores[_addr]++;
            }
        }
    }
    function getQuizQuestion(uint _index) public view returns(string memory){
        QuestionQuiz q = quizes[_index];
        return q.question();
    }

}
// File: HackHeist/IdentityFactory.sol


pragma solidity >=0.7.0 <0.9.0;





contract Factory is ProctoredQuiz{
    ERC725 token;
    mapping(address => ERC725) public information;
    uint countData;
    address FactoryOwner;
    mapping(address => bool) public verified;

    function createInstanceForAddress() public {
        address cont = address(information[msg.sender]);
        require(cont == address(0), "Instance already created");
        ERC725 tkn = new ERC725();
        information[msg.sender] = tkn;
    }

    function setDataSingle(bytes32 _key, bytes memory _value) public {
        ERC725 shard = information[msg.sender];
        shard.setDataSingle(_key, _value);
    }
    function setDataBulk(bytes32[] memory _key, bytes[] memory _value) public {
        ERC725 shard = information[msg.sender];
        shard.setData(_key, _value);
    }
    function getData(address _addr ,bytes32 _dataKey) public view returns (bytes memory){
        ERC725 shard = information[_addr];
        return shard.getData(_dataKey);
    }
    function getDataBulk(address _addr, bytes32[] memory _datakey) public view returns(bytes[] memory){
        ERC725 shard = information[_addr];
        return shard.getDataBulk(_datakey);
    }
    function isReally(address _addr)public {
        require(msg.sender == FactoryOwner,"Not permitted");
        verified[_addr] = true;
    }

}
// File: HackHeist/MintSBT.sol


pragma solidity >=0.7.0 <0.9.0;








contract MintSBT is Factory,SBT("Priyansu","Pri"){
    constructor(){
        FactoryOwner = msg.sender;
        owner = msg.sender;
    }
    event TokenOwner(address indexed addr, uint indexed tokenId);
    function _mintNft(address _to) public {
        require(totalScores[_to] > 8, "Hell Nawwww brother,go learn Qbasic XD");
        require(verified[_to] == true, "Nah dude man aint verified");
        _mint(_to);
        emit TokenOwner(_to, Supply-1);
    }
}