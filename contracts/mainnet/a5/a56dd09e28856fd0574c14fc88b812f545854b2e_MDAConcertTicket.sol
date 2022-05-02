// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./ECDSA.sol";

contract MDAConcertTicket is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string private _uri;
    uint256 public constant FRONT = 0;
    uint256 public constant CENTER = 1;
    uint256 public constant RIGHT = 2;
    uint256 public constant LEFT_CENTER = 3;
    uint256 public constant RIGHT_CENTER = 4;
    uint256 public constant LEFT = 5;

    uint256[5] positionLimit=[199,400,800,1200,2400];
    uint256[6] payPrice=[120 ether,100 ether,80 ether,60 ether,40 ether,20 ether];
    address public signAddress;
    mapping(bytes=>bool) ticketUsed;

    constructor(string memory tokenUri,address _signAddress) ERC1155("") {
        _uri=tokenUri;
        signAddress=_signAddress;
    }

    function setURI(string memory newuri) public onlyOwner {
        _uri=newuri;
    }

    function uri(uint256 tokenId) public view override returns(string memory){
        return string(
            abi.encodePacked(
                _uri,
                Strings.toString(tokenId),
                ".json" 
            )
        );
    }


    function mint(address account, uint256 id,uint256 amount, bytes memory ticket, bytes memory _singature)
        public 
    {
        require(!ticketUsed[ticket],"The ticket has been used");
        require(_verify(account,id,amount,ticket,_singature),"You don't have permission");
        tokenIdLimit(id,amount);
        _mint(account, id, amount, "");
        ticketUsed[ticket] = true;
    }

    function payMint(address account, uint256 id,uint256 amount) 
    public payable
    {
        require(msg.value >= payPrice[id] * amount,"Please pay enough");
        tokenIdLimit(id,amount);
        payable(owner()).transfer(msg.value);
        _mint(account, id, amount, "");
    }

    function compose(address account,uint256[] memory baseIds)
    public
    {
        require(baseIds.length > 1,"must be completed by two tickets");
        uint256 composeIndex = 0;
        uint256[6] memory tokenIndex=[uint256(6),5,4,3,2,1];
        uint256[] memory burnAmount= new uint256[](baseIds.length);
        for(uint256 i = 0 ; i < baseIds.length; i++){
            composeIndex += tokenIndex[baseIds[i]];
            burnAmount[i]=1;
        }
        if(composeIndex >= 6){
            composeIndex = 6;
        }
        tokenIdLimit(6 - composeIndex,1);
        _burnBatch(account,baseIds,burnAmount);
        _mint(account,6 - composeIndex, 1, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        tokenIdsLimit(ids,amounts);
        _mintBatch(to, ids, amounts, data);
    }

    function tokenIdLimit(uint256 id,uint256 amount) internal view{
        if(id <= RIGHT_CENTER){
            require(totalSupply(id) + amount <= positionLimit[id],"ticket sold out");
        }
    }

    function tokenIdsLimit(uint256[] memory ids,uint256[] memory amounts) internal view{
        for(uint256 i =0;i< ids.length;i++){
            if(ids[i] <= RIGHT_CENTER){
                require(totalSupply(ids[i]) + amounts[i] <= positionLimit[ids[i]],"ticket sold out");
            }
        }
    }

    function _verify(address to,uint256 tokenId,uint256 amount, bytes memory ticket,bytes memory _singature)internal view returns(bool){
            bytes32 ethSignedMessageHash= getEthSignedMessageHash(to,tokenId,amount,ticket);
            return signAddress == ECDSA.recover(ethSignedMessageHash,_singature);
    }
    function getSignedMessageHash(address addr,uint256 tokenId,uint256 amount,bytes memory ticket)public pure returns(bytes32){
        return keccak256(abi.encodePacked(bytes32(uint256(uint160(addr))),tokenId,amount,bytes32(ticket)));
    }

    function getEthSignedMessageHash(address addr,uint256 tokenId,uint256 amount,bytes memory ticket) public pure returns(bytes32){
        bytes32 signedMessageHash = getSignedMessageHash(addr,tokenId,amount,ticket);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",signedMessageHash));
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}