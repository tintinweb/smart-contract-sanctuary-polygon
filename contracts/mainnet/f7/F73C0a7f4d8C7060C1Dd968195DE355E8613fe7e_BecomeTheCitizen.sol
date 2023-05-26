/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.18;

abstract contract IERC20 {
    function transfer(address _to, uint256 _value) external virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external virtual returns(bytes4);
}

contract TokenAccessControl {

    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => bool) public authorizedContracts;

    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
    }

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAuthorizedContract {
        require(authorizedContracts[msg.sender]);
        _;
    }

    modifier onlyContractOwnerOrAuthorizedContract {
        require(authorizedContracts[msg.sender] || msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }

    function acceptOwnership() public ifNotPaused {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }

    function setAuthorizedContract(address _operator, bool _approve) public onlyContractOwner {
        if (_approve) {
            authorizedContracts[_operator] = true;
        } else {
            delete authorizedContracts[_operator];
        }
    }

    function setPause(bool _paused) public onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }

}

contract BecomeTheCitizen is TokenAccessControl {

    string public name;
    string public symbol;
    string public baseURI;
    uint256 public totalSupply;
    address royaltyReceiver;
    uint256 royaltyPercentage;

    uint256 lastIndex = 0;
    uint8[] digits;

    struct Citizen {
        uint8 character;
        uint8 param1;
        uint8 param2;
        uint8 param3;
        uint8 param4;
        uint8 param5;
        uint8 param6;
        uint8 param7;
        uint8 param8;
        uint8 param9;
        uint8 param10;
    }

    mapping (uint256 => Citizen) tokens;
    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => address) tokenToApproved;
    mapping (address => uint256) ownerBalance;
    mapping (address => mapping (address => bool)) ownerToOperators;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 constant private InterfaceSignature_ERC165 = 0x01ffc9a7;
    bytes4 constant private InterfaceSignature_ERC721 = 0x80ac58cd;
    bytes4 constant private InterfaceSignature_ERC2981 = 0x2a55205a;
    bytes4 constant private InterfaceSignature_ERC721Metadata =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('tokenURI(uint256)'));

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        totalSupply = 0;
    }

    function generateDigits(uint256 nonce) public returns(uint){
        delete digits;
        uint number = uint(keccak256(abi.encodePacked(block.timestamp + nonce)));
        uint returnNum = number;
        while (number > 0) {
            uint8 digit = uint8(number % 100);
            number = number / 100;
            digits.push(digit);
        }
        return returnNum;
    }
    
    function createBatchTokens(uint256 count, address toAddress) public ifNotPaused onlyContractOwner {
        for(uint256 i=0;i<count;i++){
            createToken(toAddress, i);
        }
    }

    function createToken(address toAddress, uint256 nonce) public ifNotPaused onlyContractOwner returns (uint256 tokenId) {
        this.generateDigits(nonce);

        Citizen memory _new_token;
        _new_token.character = digits[0] % 10;
        _new_token.param1 = digits[1] % 6;
        _new_token.param2 = digits[2] % 6;
        _new_token.param3 = digits[3] % 6;
        _new_token.param4 = digits[4] % 6;
        _new_token.param5 = digits[5] % 6;
        _new_token.param6 = digits[6] % 6;
        _new_token.param7 = digits[7] % 6;
        _new_token.param8 = digits[8] % 6;
        _new_token.param9 = digits[9] % 6;
        _new_token.param10 = digits[10] % 6;

        totalSupply++;
        lastIndex++;
        tokens[lastIndex] = _new_token;
        _transfer(address(0), toAddress, lastIndex);

        return lastIndex;
    }

    function getInfo(uint256 token_id) external view returns(uint8 character, uint8 p1, uint8 p2,
            uint8 p3, uint8 p4, uint8 p5, uint8 p6, uint8 p7, uint8 p8, uint8 p9, uint8 p10) {
        Citizen memory nft = tokens[token_id];
        character = nft.character;
        p1 = nft.param1;
        p2 = nft.param2;
        p3 = nft.param3;
        p4 = nft.param4;
        p5 = nft.param5;
        p6 = nft.param6;
        p7 = nft.param7;
        p8 = nft.param8;
        p9 = nft.param9;
        p10 = nft.param10;
    }

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) ||
                (_interfaceID == InterfaceSignature_ERC721) ||
                (_interfaceID == InterfaceSignature_ERC2981) ||
                (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digit;
        while (temp != 0) {
            digit++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digit);
        while (value != 0) {
            digit -= 1;
            buffer[digit] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenToOwner[_tokenId]!=address(0), "This token does not exists.");
        return string.concat(baseURI, toString(_tokenId));
    }

    function setTokenURI(string memory _baseURI) external onlyContractOwner {
        baseURI = _baseURI;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return tokenToApproved[_tokenId] == _claimant;
    }

    function _operatorFor(address _operator, address _owner) internal view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerBalance[_to]++;
        tokenToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownerBalance[_from]--;
            delete tokenToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function balanceOf(address _owner) external view returns (uint256 count) {
        require(_owner != address(0));
        return ownerBalance[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = tokenToOwner[_tokenId];
        require(owner != address(0));
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external ifNotPaused {
        require(_owns(msg.sender, _tokenId) ||
                _approvedFor(msg.sender, _tokenId) ||
                ownerToOperators[tokenToOwner[_tokenId]][msg.sender]);  // owns, is approved or is operator
        require(_to != address(0) && _to != address(this));  // valid address
        require(tokenToOwner[_tokenId] != address(0));  // is valid NFT

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external ifNotPaused {
        this.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external ifNotPaused {
        this.safeTransferFrom(_from, _to, _tokenId, "");
    }

    function approve(address _to, uint256 _tokenId) external ifNotPaused {
        require(_owns(msg.sender, _tokenId) ||
                _operatorFor(msg.sender, this.ownerOf(_tokenId)));

        tokenToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function setApprovalForAll(address _to, bool _approved) external ifNotPaused {
        if (_approved) {
            ownerToOperators[msg.sender][_to] = _approved;
        } else {
            delete ownerToOperators[msg.sender][_to];
        }
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(tokenToOwner[_tokenId] != address(0));
        return tokenToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function setRoyalty(address _receiver, uint8 _percentage) external onlyContractOwner {
        royaltyReceiver = _receiver;
        royaltyPercentage = _percentage;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        _tokenId = _tokenId;
        receiver = royaltyReceiver;
        royaltyAmount = uint256(_salePrice / 100) * royaltyPercentage;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }

    function withdrawTokenBalance(address _address, uint256 _amount) external onlyContractOwner {
        IERC20 token = IERC20(_address);
        token.transfer(msg.sender, _amount);
    }
}