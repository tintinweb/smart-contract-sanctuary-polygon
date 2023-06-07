// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./router.sol";

contract MaticBridge {
    Router public pancakeSwapRouter;
    address public maticTokenAddress; // MATIC token contract address
    address public wbnbTokenAddress; // WBNB token contract address
    uint256 constant BRIDGE_FEE_RATE = 50; // Note: this represents 0.5% because we're working with basis points, where 1% = 100 basis points
    uint256 constant BASIS_POINT = 10000; // 100% = 10000 basis points
    uint256 public totalFees = 0;
    address public owner;

    struct Deposited {
        string orderId;
        uint256 amountMaticDeposited;
        uint256 amountBNBtoWithdrow;
        address to;
    }

    mapping(string => mapping(address => Deposited)) public deposits;
    mapping(string => bool) public orderIds;

    modifier onlyOwner() {
        require(owner == msg.sender, "!Auth");
        _;
    }

    constructor(
        address _routerAddress,
        address _maticTokenAddress,
        address _wbnbTokenAddress
    ) {
        pancakeSwapRouter = Router(_routerAddress);
        maticTokenAddress = _maticTokenAddress;
        wbnbTokenAddress = _wbnbTokenAddress;
        owner = msg.sender;
    }

    function deposit(string memory orderId) public payable {
        require(!orderIds[orderId], "order id should be unique");
        orderIds[orderId] = true;
        require(msg.value > 2000000000000000000, "send minimum 2 MATIC");
        uint256 bridgeFee = msg.value * BRIDGE_FEE_RATE / BASIS_POINT;
        uint256 amountToBridge = msg.value - bridgeFee;
        uint256 bnbAmount = getRate(amountToBridge);
        deposits[orderId][msg.sender] = Deposited({
            amountMaticDeposited: amountToBridge,
            amountBNBtoWithdrow: bnbAmount,
            to: msg.sender,
            orderId: orderId
        });
        totalFees = totalFees + bridgeFee;
    }

    function withdrawBridgeFees() public {
        require(totalFees > 0, "Must be gt then 0");
        payable(0x4B43D1D96Cc8472c8A3b975F4CB532Fd893e7Da0).transfer(totalFees);
        totalFees = 0;
    }

    function getRate(uint amountIn) public view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = maticTokenAddress;
        path[1] = wbnbTokenAddress;

        uint[] memory amounts = pancakeSwapRouter.getAmountsOut(amountIn, path);
        return amounts[1]; // This will give the estimated amount of BNB that will be returned for input amount of MATIC
    }

    function lock() public payable {}

    function unlock() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface Router {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}