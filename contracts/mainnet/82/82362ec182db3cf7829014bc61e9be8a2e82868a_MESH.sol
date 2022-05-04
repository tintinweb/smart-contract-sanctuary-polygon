/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// MESH token
//
// https://meshswap.fi 

pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

interface IFactory {
    function poolExist(address) external view returns (bool);
}

interface IGovernance {
    function factory() external view returns (address);
}

contract MESH {
    using SafeMath for uint256;

    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed holder, address indexed spender, uint amount);

    string public constant name = "Meshswap Protocol";
    string public constant symbol = "MESH";
    uint8 public constant decimals = 18;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    // ======== Construction & Init ========
    address public owner;
    address public nextOwner;
    
    uint public miningAmount;
    uint public halfLife;
    uint public minableBlock;
    uint public teamRatio;
    uint public blockAmount;
    uint public rewarded;    
    uint public minableTime;

    address public teamWallet;
    uint public teamAward;

    bool public entered;

    constructor(
        uint _miningAmount,
        uint _blockAmount, 
        uint _halfLife, 
        uint _minableTime,
        uint _teamRatio, 
        uint _initialSupply
    ) public {
        owner = msg.sender;

        miningAmount = _miningAmount;
        blockAmount = _blockAmount;
        halfLife = _halfLife;
        minableTime = _minableTime;
        minableBlock = uint(-1);
        teamRatio = _teamRatio;
        
        totalSupply = totalSupply.add(_initialSupply);
        balanceOf[msg.sender] = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    // ======== ERC20 =========
    function transfer(address _to, uint _value) public returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function burn(uint amount) public {
        address user = msg.sender;
        require(balanceOf[user] >= amount);

        balanceOf[user] = balanceOf[user].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(user, address(0), amount);
    }

    // ======== Administration ========
    
    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);
    event ChangeTeamWallet(address _teamWallet);
    event ClaimTeamAward(uint award, uint totalAward);
    event SetMinableBlock(uint startTime, uint newMinableBlock);

    function changeNextOwner(address _nextOwner) public {
        require(msg.sender == owner);
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);
        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function changeTeamWallet(address _teamWallet) public {
        require(msg.sender == owner);
        teamWallet = _teamWallet;

        emit ChangeTeamWallet(_teamWallet);
    }

    function claimTeamAward() public {
        require(teamWallet != address(0));

        uint nowBlock = block.number;

        if (nowBlock >= minableBlock) {
            uint totalAward = mined().mul(teamRatio).div(uint(100).sub(teamRatio));

            if (totalAward > teamAward) {
                uint award = totalAward - teamAward;

                balanceOf[teamWallet] = balanceOf[teamWallet].add(award);
                totalSupply = totalSupply.add(award);

                emit ClaimTeamAward(award, totalAward);
                emit Transfer(address(0), teamWallet, award);

                teamAward = totalAward;
            }
        }
    }

    function setMinableBlock() public {
        require(block.timestamp >= minableTime, "Did not reached minableTime");
        require(minableBlock == uint(-1), "MinableBlock already set.");

        minableBlock = block.number;

        emit SetMinableBlock(block.timestamp, minableBlock);
    }
    
    function mined() public view returns (uint res) {
        uint256 nowBlock = block.number;
        uint256 startBlock = minableBlock;
        if (nowBlock < startBlock) return 0;

        uint blockAmt = blockAmount.mul(uint(100).sub(teamRatio)).div(100);

        uint256 level = ((nowBlock.sub(startBlock)).add(1)).div(halfLife);

        for (uint256 i = 0; i < level; i++){
            if (startBlock.add(halfLife) > nowBlock) break;

            res = res.add(blockAmt.mul(halfLife));
            startBlock = startBlock.add(halfLife);
            blockAmt = blockAmt.div(2);
        }
        
        res = res.add(blockAmt.mul((nowBlock.sub(startBlock)).add(1)));
        if (miningAmount != 0) res = res > miningAmount ? miningAmount : res;
    }

    function sendReward(address user, uint amount) public {
        require(msg.sender == owner || IFactory(IGovernance(owner).factory()).poolExist(msg.sender));
        require(amount.add(rewarded) <= mined());

        rewarded = rewarded.add(amount);
        balanceOf[user] = balanceOf[user].add(amount);
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), user, amount);
    }

    event RefixMining(uint blockNumber, uint newBlockAmount, uint newHalfLife);

    function refixMining(uint newBlockAmount, uint newHalfLife) public {
        require(msg.sender == owner);
        require(blockAmount != newBlockAmount);
        require(halfLife != newHalfLife);
        require(newHalfLife.mul(newBlockAmount) == halfLife.mul(blockAmount));

        uint nowBlock = block.number;
        uint newMinableBlock = nowBlock.sub(nowBlock.sub(minableBlock).mul(newHalfLife).div(halfLife));       

        minableBlock = newMinableBlock;
        blockAmount = newBlockAmount;
        halfLife = newHalfLife;
        
        emit RefixMining(block.number, newBlockAmount, newHalfLife);
    }

    function getCirculation() public view returns (uint blockNumber, uint nowCirculation) {
        blockNumber = block.number;
        nowCirculation = mined().mul(100).div(uint(100).sub(teamRatio));
    }

    function () payable external { revert(); }
}