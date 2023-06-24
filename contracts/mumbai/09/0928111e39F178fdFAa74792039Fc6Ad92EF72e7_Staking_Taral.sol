// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//0xF92970452FCd652fab37023C4fBf01D348EaCD40
// vicky.kumar


contract BusdToken {
    string  public name = "BUSD Token";
    string  public symbol = "BUSD";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BusdToken.sol";
//0xF92970452FCd652fab37023C4fBf01D348EaCD40 Token;
//0xC7676acE0062Fec10e7acBf8ca8355d763ba6E9D smart contract;

contract Staking_Taral {
    address public owner;
    BusdToken public busdToken;
    struct Position {
        uint256 positionId;
        address walletAddress;
        uint256 createdDate;
        uint256 unlockDate;
        uint256 percentInterest;
        uint256 tokenStaked;
        uint256 tokenInterest;
         uint256 lastInterestWithdrawn;
        bool open;
        
        

       
    }
   
    Position public position;
    uint256 public currentPositionId;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) public positionIdsByAddress;
    mapping(uint256 => uint256) public tiers;
    uint256[] public lockPeriods;
      mapping(uint256 => mapping(uint256 => bool)) public dailyInterestWithdrawn;

    string public name = "Taral App";

    constructor(address _busdToken) {
        owner = msg.sender;
        busdToken = BusdToken(_busdToken);
        currentPositionId = 0;
    }

    function calculateInterest(
        uint256 basisPoints,
        uint256 numDays,
        uint256 tokenAmount
    ) public pure returns (uint256) {
        return (basisPoints * numDays * tokenAmount) / (10000 * 365);
    }

    function adminCreatePools(uint256 numDays, uint256 basisPoints) external {
        require(owner == msg.sender, "Only owner may modify staking periods");

        tiers[numDays] = basisPoints;
        lockPeriods.push(numDays);
    }
    

    function getLockPeriods() external view returns (uint256[] memory) {
        return lockPeriods;
    }

    function getInterestRate(uint256 numDays) external view returns (uint256) {
        return tiers[numDays];
    }
    function getBalance() external view returns (uint256) {
        return busdToken.balanceOf(address(this));
    }

    function getPositionById(uint256 positionId)
        external
        view
        returns (Position memory)
    {
        return positions[positionId];
    }

    function getPositionIdsForAddress(address walletAddress)
        external
        view
        returns (uint256[] memory)
    {
        return positionIdsByAddress[walletAddress];
    }

    function changeUnlockDate(uint256 positionId, uint256 newUnlockDate)
        external
    {
        require(owner == msg.sender, "Only owner may modify staking periods");

        positions[positionId].unlockDate = newUnlockDate;
    }

    function stakeToken(uint256 numDays, uint256 tokenAmount) public payable {
        require(tiers[numDays] > 0, "adminCreatePools");
        require(tokenAmount >= 1 ether, "Minimum token stake is 1 token");
        
        require(
            busdToken.transferFrom(msg.sender, address(this), tokenAmount),
            "Token transfer failed"
        );

        positions[currentPositionId] = Position(
            currentPositionId,
            msg.sender,
            block.timestamp,
            block.timestamp + (numDays * 1 days),
            tiers[numDays],
            tokenAmount,
            calculateInterest(tiers[numDays], numDays, tokenAmount),
            0,
             true
             
        );
        positionIdsByAddress[msg.sender].push(currentPositionId);
        currentPositionId += 1;
    }

    // 
 function withdrawInterest(uint256 positionId) external {
        Position storage pos = positions[positionId];
        require(
            pos.walletAddress == msg.sender,
            "Only owner may withdraw interest"
        );

        require(pos.open == true, "Position is closed");
        require(pos.unlockDate <= block.timestamp, "Unlock date not reached");

        uint256 lastWithdrawn = pos.lastInterestWithdrawn;
        uint256 currentDay = block.timestamp / 1 days;

        require(
            !dailyInterestWithdrawn[positionId][currentDay],
            "Interest already withdrawn today"
        );

        require(
            currentDay > lastWithdrawn,
            "Interest already withdrawn for today"
        );

        uint256 interestAmount = pos.tokenInterest;
        busdToken.transfer(msg.sender, interestAmount);

        pos.lastInterestWithdrawn = currentDay;
        dailyInterestWithdrawn[positionId][currentDay] = true;
    }


     function closePosition(uint256 positionId) external {
        require(
            positions[positionId].walletAddress == msg.sender,
            "Only owner may modify position"
        );
        require(positions[positionId].open == true, "Poition is closed");

        positions[positionId].open = false;
        if (block.timestamp > positions[positionId].unlockDate) {
            uint256 tokenAmount = positions[positionId].tokenStaked +
                positions[positionId].tokenInterest;

            busdToken.transfer(msg.sender, tokenAmount);
        } else {
            payable(msg.sender).call{value: positions[positionId].tokenStaked}("");
        }
    }
}