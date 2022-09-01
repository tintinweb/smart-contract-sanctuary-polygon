/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    uint256 public chainId;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint256) private nonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function nonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Zero address");
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(allowances[from][msg.sender] >= amount, "Not enough allowance");
        allowances[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "Zero address");
        require(balances[from] >= amount, "Not enough balance to transfer");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function DOMAIN_SEPERATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Test")),
                    keccak256(bytes("v1")),
                    chainId,
                    address(this)
                )
            );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(deadline > block.timestamp, "Expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPERATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );

        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0) && signer == owner, "Invalid signature");
        allowances[owner][spender] = value;
        nonces[owner]++;
        emit Approval(owner, spender, value);
        return true;
    }
}