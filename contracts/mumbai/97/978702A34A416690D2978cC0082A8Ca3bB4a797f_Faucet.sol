// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

contract Faucet {
    uint256 public waitTime = 1 minutes;
    uint256 public tokenAmount = 100000000000000000000;
    ERC20 public tokenUSDCInstance;
    ERC20 public tokenUSDTInstance;

    mapping(address => mapping(address => uint256)) lastAccessTime;

    constructor(address _tokenUSDC, address _tokenUSDT) payable {
        tokenUSDCInstance = ERC20(_tokenUSDC);
        tokenUSDTInstance = ERC20(_tokenUSDT);
    }

    function requestTokens(address _erc20) public {
        require(
            allowedToWithdraw(msg.sender, _erc20) == true,
            "Insufficient time elapsed since last withdrawal - try again later."
        );
        lastAccessTime[_erc20][msg.sender] = block.timestamp + waitTime;
        if (address(tokenUSDCInstance) == _erc20) {
            tokenUSDCInstance.transfer(msg.sender, tokenAmount);
        }
        if (address(tokenUSDTInstance) == _erc20) {
            tokenUSDTInstance.transfer(msg.sender, tokenAmount);
        }
    }

    function allowedToWithdraw(
        address _address,
        address _erc20
    ) public view returns (bool) {
        require(
            address(tokenUSDCInstance) == _erc20 ||
                address(tokenUSDTInstance) == _erc20,
            "address invalid"
        );
        if (lastAccessTime[_erc20][_address] == 0) {
            return true;
        } else if (block.timestamp >= lastAccessTime[_erc20][_address]) {
            return true;
        }
        return false;
    }

    function setTimeFaucet(uint256 _time) public onlyOwner {
        waitTime = _time;
    }

    function setAmountFaucet(uint256 _amount) public onlyOwner {
        tokenAmount = _amount;
    }

    modifier onlyOwner() {
        require(
            msg.sender == address(0xA8876050F63a4D6c3fa78a60404Aea0c3EA2D83a),
            "Only the contract owner can call this function"
        );
        _;
    }
}