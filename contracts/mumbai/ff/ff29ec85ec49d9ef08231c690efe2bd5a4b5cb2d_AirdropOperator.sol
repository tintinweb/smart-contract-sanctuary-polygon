/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

pragma solidity 0.5.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IDistribution {
    function estimateEndBlock() external view returns (uint);
    function totalAmount() external view returns (uint);
    function blockAmount() external view returns (uint);
    function distributableBlock() external view returns (uint);
    function distribution() external view returns (uint);
    function targetEntries(uint) external view returns (address);
    function targetCount() external view returns (uint);
    function distributionRate(address) external view returns (uint);
}

interface ITreasury {
    function fee() external view returns (uint);
    function validOperator(address) external view returns (bool);
    function distributions(address, address) external view returns (address);
    function createETHDistribution(uint, uint, address[] calldata, uint[] calldata) external payable;
    function createTokenDistribution(address, uint, uint, uint, address[] calldata, uint[] calldata) external;
    function depositETH() external payable;
    function depositToken(address, uint) external;
    function refixBlockAmount(address, uint) external;
    function refixDistributionRate(address, address[] calldata, uint[] calldata) external;
}

interface IFactory {
    function poolExist(address) external view returns (bool);
}

contract AirdropOperator {
    address constant public treasury = 0x7E6863De2aAf37320d1a755FF50EB182455c8256;
    address constant public factory = 0x48eB6bdD4ff9FeCECaf64bB2c0435ac654186386;
    address constant public mesh = 0x6a5d8703e612CFe33388Cf0C92d409934Fad98Cb;

    address public owner;
    address public nextOwner;
    address public token;
    address public lp;

    constructor(address _owner, address _token, address _lp) public {
        owner = _owner;

        token = _token;
        require(IERC20(token).decimals() != 0);

        lp = _lp;
        require(IFactory(factory).poolExist(lp));
    }

    function version() external pure returns (string memory) {
        return "AirdropOperatorDeployedByManager20220916";
    }

    // valid fallback
    function () payable external { revert(); }

    // ======================= owner method ===========================

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeNextOwner(address _nextOwner) public onlyOwner {
        nextOwner = _nextOwner;
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);

        owner = nextOwner;
        nextOwner = address(0);
    }

    //withdraw tokens remaining in the operator contract
    function withdraw(address tokenAddr) public onlyOwner {
        uint balance = 0;
        if (tokenAddr == address(0)){
            balance = (address(this)).balance;
            if (balance > 0){
                (bool res, ) = owner.call.value(balance)("");
                require(res);
            }
        }
        else {
            balance = IERC20(tokenAddr).balanceOf(address(this));
            if(balance > 0) {
                require(IERC20(tokenAddr).transfer(owner, balance));
            }
        }
    }

    // ====================== Stat ====================================

    function getAirdropStat() public view returns (
        address distributionContract, // airdrop distribution contract address
        uint totalAmount, // Total amount of tokens to be distributed
        uint blockAmount, // Amount of tokens to be distributed per block
        uint distributableBlock, // Block number to airdrop start
        uint endBlock, // Block number to airdrop end
        uint distributed,  // Amount of tokens distributed
        uint remain, // amount remaining in the contract
        uint targetCount, // airdrop target LP count
        address[] memory targets, // airdrop target LP list
        uint[] memory rates // airdrop target lp rate list
    ){
        distributionContract = ITreasury(treasury).distributions(address(this), token);

        IDistribution dis = IDistribution(distributionContract);
        totalAmount = dis.totalAmount();
        blockAmount = dis.blockAmount();
        distributableBlock = dis.distributableBlock();
        endBlock = dis.estimateEndBlock();
        distributed = dis.distribution();

        remain = IERC20(token).balanceOf(distributionContract);

        targetCount = dis.targetCount();
        targets = new address[](targetCount);
        rates = new uint[](targetCount);

        for(uint i = 0; i < targetCount; i++){
            targets[i] = dis.targetEntries(i);
            rates[i] = dis.distributionRate(targets[i]);
        }
    }

    // ===================== Airdrop method ===========================
    ///@param totalAmount : Total amount of tokens to be distributed
    ///@param blockAmount : Amount of tokens to be distributed per block
    ///@param startBlock  : Block number to airdrop start
    function createDistribution(
        uint totalAmount,
        uint blockAmount,
        uint startBlock
    ) public onlyOwner {
        ITreasury Treasury = ITreasury(treasury);

        require(Treasury.validOperator(address(this)));
        require(Treasury.distributions(address(this), token) == address(0));
        require(startBlock >= block.number);

        address[] memory targets = new address[](1);
        targets[0] = lp;

        uint[] memory rates = new uint[](1);
        rates[0] = 100;

        if (Treasury.fee() > 0) {
            require(IERC20(mesh).balanceOf(address(this)) >= Treasury.fee());
            require(IERC20(mesh).approve(treasury, Treasury.fee()));
        }

        require(IERC20(token).balanceOf(address(this)) >= totalAmount);
        require(IERC20(token).approve(treasury, totalAmount));
        Treasury.createTokenDistribution(token, totalAmount, blockAmount, startBlock, targets, rates);
    }

    // Airdrop token deposit
    ///@param amount : Amount of airdrop token to deposit
    function deposit(uint amount) public onlyOwner {
        ITreasury Treasury = ITreasury(treasury);

        require(Treasury.validOperator(address(this)));
        require(Treasury.distributions(address(this), token) != address(0));
        require(amount != 0);

        require(IERC20(token).balanceOf(address(this)) >= amount);
        require(IERC20(token).approve(treasury, amount));
        Treasury.depositToken(token, amount);
    }

    // Airdrop amount per block modification function
    // The function is applied immediately from the called block
    ///@param blockAmount : airdrop block amount to change
    function refixBlockAmount(uint blockAmount) public onlyOwner {
        ITreasury Treasury = ITreasury(treasury);

        require(Treasury.validOperator(address(this)));
        require(Treasury.distributions(address(this), token) != address(0));
        require(blockAmount != 0);

        Treasury.refixBlockAmount(token, blockAmount);
    }
}