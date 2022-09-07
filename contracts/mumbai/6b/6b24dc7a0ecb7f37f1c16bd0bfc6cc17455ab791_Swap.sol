/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,                  
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens  
        bytes memory payload
    ) external;
}

contract Swap is IStargateReceiver {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReceivedOnDestination(address token, uint amountLD);

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    address public stargateRouter;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/ 

    constructor(address _stargateRouter) {
        stargateRouter = _stargateRouter;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTERS
    //////////////////////////////////////////////////////////////*/

    function setStargateRouter(address router) external {
        stargateRouter = router;
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @param qty The qty of local _token contract tokens  
    /// @param bridgeToken The local bridge token address 
    /// @param dstChainId The destination chain id
    /// @param srcPoolId The source Stargate poolId
    /// @param dstPoolId The destination Stargate poolId
    /// @param to The bytes containing the toAddress
    /// @param destStargateComposed The destination chain receiving contract address
    function swap(
        uint qty,
        address bridgeToken,                    
        uint16 dstChainId,                      
        uint16 srcPoolId,                       
        uint16 dstPoolId,                       
        address to,                             
        address destStargateComposed            
    ) external payable {
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message");
        require(qty > 0, "error: swap() requires qty > 0");

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(to);

        // this contract calls stargate swap()
        ERC20(bridgeToken).transferFrom(msg.sender, address(this), qty);
        ERC20(bridgeToken).approve(address(stargateRouter), qty);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value:msg.value}(
            dstChainId,                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            qty,                                            // total tokens to send to destination chain
            0,                                              // min amount allowed out
            IStargateRouter.lzTxObj(200000, 0, "0x"),       // default lzTxObj
            abi.encodePacked(destStargateComposed),         // destination address, the sgReceive() implementer
            data                                            // bytes payload
        );
    }

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens  
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16 _chainId, 
        bytes memory _srcAddress, 
        uint _nonce, 
        address _token, 
        uint amountLD, 
        bytes memory _payload
    ) override external {
        require(
            msg.sender == address(stargateRouter), 
            "only stargate router can call sgReceive!"
        );

        (address _toAddr) = abi.decode(_payload, (address));
        ERC20(_token).transfer(_toAddr, amountLD);
        emit ReceivedOnDestination(_token, amountLD);
    }
}