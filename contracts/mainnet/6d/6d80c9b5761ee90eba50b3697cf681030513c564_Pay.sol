contract Pay {
    mapping(address => mapping(uint256 => Listing)) public listings;

    address public owner;
    address payable public feeAddress;

    constructor() payable {
        owner = (msg.sender);
        feeAddress = payable(msg.sender);
    }

    struct Listing {
        address payable settlementAddress;
        uint256 settlementAmount;
        uint256 amount;
        address buyer;
        bool isBuayble;
        bool isSold;
        uint256 prepareTimestamp;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function purchase(address contractAddr, uint256 tokenId) public payable{
        Listing memory item = listings[contractAddr][tokenId];

        uint256 purchaseTime = 180;

        require(msg.sender == item.buyer, "Caller must be same with the buyer");
        require(item.isBuayble == true, "NFT must be buyable");
        require(block.timestamp <= item.prepareTimestamp + purchaseTime, "Purchase time over");
        require(msg.value == item.amount, "Insufficient funds sent");

        if(item.settlementAmount == msg.value) {
            item.settlementAddress.transfer(msg.value);
        }else if(item.settlementAmount > 0 && item.settlementAmount < msg.value){
            item.settlementAddress.transfer(item.settlementAmount);
            (feeAddress).transfer(msg.value - item.settlementAmount);
        }else {
            (feeAddress).transfer(msg.value);
        }

        listings[contractAddr][tokenId] = Listing(item.settlementAddress, item.settlementAmount, msg.value, msg.sender, false, true, item.prepareTimestamp);
    }

    function preparePurchase(
        address contractAddr,
        uint256 tokenId,
        address payable settlementAddress,
        uint256 settlementAmount,
        uint amount,
        address buyer
    ) public onlyOwner{
        Listing memory item = listings[contractAddr][tokenId];

        require(!item.isSold, "NFT is sold");
        require(item.settlementAmount <= amount, "Insufficient settlement");

        listings[contractAddr][tokenId] = Listing(settlementAddress, settlementAmount, amount, buyer, true, false, block.timestamp);
    }

    function deleteItem(address contractAddr, uint256 tokenId) public onlyOwner{
        delete listings[contractAddr][tokenId];
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        owner = newOwner;
    }

    function changeFeeAddress(address payable newFeeAddress) public onlyOwner{
        require(newFeeAddress != address(0));
        feeAddress = newFeeAddress;
    }

}