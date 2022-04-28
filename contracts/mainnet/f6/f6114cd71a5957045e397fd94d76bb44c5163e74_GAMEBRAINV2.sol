/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// File: contracts/gamebrain.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function mintTokens(address to, uint256 amount) external;
}

contract GAMEBRAINV2 {
    address signer;
    address owner;
    IERC20 token;
    bool tokenSet;
    uint256 public price;
    mapping(uint256 => bool) usedNonces;
    event Deposit(address indexed from, uint256 value);

    constructor(uint256 _price, address _signer) {
        owner = msg.sender;
        signer = _signer;
        price = _price;
    }

    function setToken(address _tokenAddress) private {
        token = IERC20(_tokenAddress);
        tokenSet = true;
    }

    function setAndInitToken(address _token, uint256 tokensPerUser) public {
        require(msg.sender == owner, "Not Authorized");
        setToken(_token);
        token.mintTokens(address(this), tokensPerUser * 888 * 10**18);
    }

    function changeSigner(address _newSigner) public {
        require(msg.sender == owner, "Not Authorized");
        signer = _newSigner;
    }

    function changePrice(uint256 _newPrice) public {
        require(msg.sender == owner, "Not Authorized");
        price = _newPrice;
    }

    function buyTokens(uint256 _amount) public payable {
        require(tokenSet == true, "Contract Not Activated");
        require(_amount != 0);
        require(_amount * price == msg.value, "Not Enough Money sent");
        token.mintTokens(msg.sender, _amount * 10**18);
        (bool payout, ) = payable(owner).call{value: msg.value}("");
        require(payout, "Transfer failed.");
    }

    function buyAndDepositTokens(uint256 _amount) public payable {
        require(tokenSet == true, "Contract Not Activated");
        require(_amount != 0);
        require(_amount * price == msg.value, "Not Enough Money sent");
        uint256 amount = _amount * 10**18;
        token.mintTokens(address(this), amount);
        (bool payout, ) = payable(owner).call{value: msg.value}("");
        require(payout, "Transfer failed.");
        emit Deposit(msg.sender, amount);
    }

    function claimTokens(
        uint256 amountUser,
        uint256 amountHouse,
        uint256 nonce,
        bytes memory sig
    ) public {
        require(tokenSet == true, "Contract Not Activated");
        require(!usedNonces[nonce], "Tokens Already Claimed");
        usedNonces[nonce] = true;
        bytes32 message = prefixed(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    amountUser,
                    amountHouse,
                    nonce,
                    this
                )
            )
        );
        require(
            recoverSigner(message, sig) == signer,
            "Signature Not Authentic."
        );
        require(token.transfer(msg.sender, amountUser));
        require(token.transfer(owner, amountHouse));
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}