/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    uint256 public totalOwners;
    address[] public _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        _owners.push(_msgSender());
        totalOwners++;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        _owners.push(newOwner);
        totalOwners++;
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
        
        for(uint i = 0; i < _owners.length; i++){
            if(_owners[i] == _Owner){
                for(uint j = i; j < _owners.length-1; j++){
                    _owners[j] = _owners[j+1];      
                }
                _owners.pop();
            }
        }
        
        
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }

}


contract VerifySignature is Ownable {
    
    function getMessageHash(
        address _to
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        bytes memory signature
    ) internal view returns (bool) {
        require(_signer == owner() || verifyOwner(_signer) == true, "Signer should be owner only.");
        bytes32 messageHash = getMessageHash(msg.sender);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

    }
}

contract PrivateSale is VerifySignature{
    uint256 public tokenPrice;
    uint256 public minLimit;
    uint256 public maxLimit;
    uint256 public remainingTokens;
    bool public saleStatus;
    //Re-Entrancy guard
    bool internal locked;
   
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(){
        saleStatus = false;
        tokenPrice = 0;
        minLimit = 0;
        maxLimit = 0;
    }

    function updateMinLimit(uint256 _minLimit) public onlyOwner{
        minLimit = _minLimit;
    }

    function updateMaxLimit(uint256 _maxLimit) public onlyOwner{
        maxLimit = _maxLimit;
    }

    function updateTokenPrice(uint256 _tokenPrice) public onlyOwner{
        tokenPrice = _tokenPrice;
    }

    // OWNER NEED TO CALL THIS FUNCTION BEFORE START ICO
    // OWNER ALSO NEED TO SET A GOAL OF TOKEN AMOUNT FOR FUND RAISING
    // THIS FUNCTION WILL TRANSFER THE TOKENS FROM OWNER TO CONTRACT
    function startBuying(uint256 tokenAmount, uint256 price) public onlyOwner{
        require(tokenAmount > 0 && price > 0, "Token Amount or price is wrong.");
        require(saleStatus != true, "Sale is already started.");
        minLimit = 1000;
        maxLimit = 10000;
        saleStatus = true;
        remainingTokens = tokenAmount;
        tokenPrice = price;
    }

    
    //  THIS FUMCTION WILL BE USED BY INVESTOR FOR BUYING TOKENS
    //  IF THE OWNER WILL END ICO THEN NO ONE CAN INVEST ANYMORE 
    function buyToken(bytes memory _signature, uint256 amountOfToken, address signer) public noReentrant payable{
        require(verify(signer, _signature), "You are not Whitelisted.");
        require(saleStatus == true, "TokenSale is ended.");
        require(amountOfToken >= minLimit,"You are exceeding min value.");
        require(amountOfToken <= maxLimit,"You are exceeding max value.");
        
        (bool success,) = owner().call{value: msg.value}("");
        if(!success) {
            revert("Payment Sending Failed");
        }else{
            remainingTokens -= amountOfToken; 
        }
    }

    function endSale() public onlyOwner{
        require(saleStatus != false, "Sale is not started.");
        saleStatus = false;
        remainingTokens = 0;
        tokenPrice = 0;
        minLimit = 0;
        maxLimit = 0;
    }
}