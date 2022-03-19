// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./IBridge.sol";
import "./RelayRecipient.sol";
import "./SolanaSerialize.sol";
import "../utils/Typecast.sol";

//TODO: relocate
interface IERC20 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract Portal is RelayRecipient, SolanaSerialize, Typecast {
    mapping(address => uint256) public balanceOf;
    string public versionRecipient;
    address public bridge;
    address public proxy;

    bytes public constant sighashMintSyntheticToken =
        abi.encodePacked(uint8(44), uint8(253), uint8(1), uint8(101), uint8(130), uint8(139), uint8(18), uint8(78));
    bytes public constant sighashEmergencyUnburn =
        abi.encodePacked(uint8(149), uint8(132), uint8(104), uint8(123), uint8(157), uint8(85), uint8(21), uint8(161));

    enum SynthesizePubkeys {
        chain2address,
        receiveSide,
        receiveSideData,
        oppositeBridge,
        oppositeBridgeData,
        syntToken,
        syntTokenData,
        txState
    }

    enum RequestState {
        Default,
        Sent,
        Reverted
    }
    enum UnsynthesizeState {
        Default,
        Unsynthesized,
        RevertRequest
    }

    struct TxState {
        bytes32 recipient;
        bytes32 chain2address;
        uint256 amount;
        bytes32 rtoken;
        RequestState state;
    }

    struct SynthParams {
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        uint256 chainID;
    }

    struct PermitData {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        bool approveMax;
    }

    mapping(bytes32 => TxState) public requests;
    mapping(bytes32 => UnsynthesizeState) public unsynthesizeStates;
    mapping(bytes32 => uint8) public tokenDecimals;

    event SynthesizeRequest(
        bytes32 indexed _id,
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        address _token
    );
    event SynthesizeRequestSolana(
        bytes32 indexed _id,
        address indexed _from,
        bytes32 indexed _to,
        uint256 _amount,
        address _token
    );
    event RevertBurnRequest(bytes32 indexed _id, address indexed _to);
    event BurnCompleted(bytes32 indexed _id, address indexed _to, uint256 _amount, address _token);
    event RevertSynthesizeCompleted(bytes32 indexed _id, address indexed _to, uint256 _amount, address _token);
    event RepresentationRequest(address indexed _rtoken);
    event ApprovedRepresentationRequest(bytes32 indexed _rtoken);

    function initializeFunc(address _bridge, address _trustedForwarder) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        versionRecipient = "2.2.3";
        bridge = _bridge;
        _setTrustedForwarder(_trustedForwarder);
    }

    modifier onlyBridge() {
        require(bridge == msg.sender, "Portal: bridge only");
        _;
    }

    modifier onlyTrusted() {
        require(bridge == msg.sender || proxy == msg.sender, "Portal: only trusted contract");
        _;
    }

    /**
     * @dev Synthesize token request.
     * @param _token token address to synthesize
     * @param _amount amount to synthesize
     * @param _chain2address amount recipient address
     * @param _receiveSide request recipient address
     * @param _oppositeBridge opposite bridge address
     * @param _chainID opposite chain ID
     */
    function synthesize(
        address _token,
        uint256 _amount,
        address _chain2address,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainID
    ) external returns (bytes32 txID) {
        // require(tokenDecimals[castToBytes32(_token)] > 0, "Portal: token must be verified");

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] += _amount;

        uint256 nonce = IBridge(bridge).getNonce(_msgSender());
        txID = IBridge(bridge).prepareRqId(
            castToBytes32(_oppositeBridge),
            _chainID,
            castToBytes32(_receiveSide),
            castToBytes32(_msgSender()),
            nonce
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(keccak256(bytes("mintSyntheticToken(bytes32,address,uint256,address)"))),
            txID,
            _token,
            _amount,
            _chain2address
        );
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainID, txID, _msgSender(), nonce);
        TxState storage txState = requests[txID];
        txState.recipient = castToBytes32(_msgSender());
        txState.chain2address = castToBytes32(_chain2address);
        txState.rtoken = castToBytes32(_token);
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    /**
     * @dev Synthesize token request with bytes32 support for Solana.
     * @param _token token address to synthesize
     * @param _amount amount to synthesize
     * @param _pubkeys synth data for Solana
     * @param _txStateBump transaction state bump
     * @param _chainId opposite chain ID
     */
    function synthesizeToSolana(
        address _token,
        uint256 _amount,
        bytes32[] calldata _pubkeys,
        bytes1 _txStateBump,
        uint256 _chainId
    ) external returns (bytes32 txID) {
        // require(tokenDecimals[castToBytes32(_token)] > 0, "Portal: token must be verified");

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] += _amount;

        require(_chainId == SOLANA_CHAIN_ID, "Portal: incorrect chainID");

        // TODO: fix amount digits for solana (digits 18 -> 6)
        require(_amount < type(uint64).max, "Portal: amount too large");
        uint64 solAmount = uint64(_amount);
        // swap bytes
        solAmount = ((solAmount & 0xFF00FF00FF00FF00) >> 8) | ((solAmount & 0x00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        solAmount = ((solAmount & 0xFFFF0000FFFF0000) >> 16) | ((solAmount & 0x0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        solAmount = (solAmount >> 32) | (solAmount << 32);

        uint256 nonce = IBridge(bridge).getNonce(_msgSender());
        txID = IBridge(bridge).prepareRqId(
            _pubkeys[uint256(SynthesizePubkeys.oppositeBridge)],
            SOLANA_CHAIN_ID,
            _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
            castToBytes32(_msgSender()),
            nonce
        );

        SolanaAccountMeta[] memory accounts = new SolanaAccountMeta[](9);
        accounts[0] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.receiveSideData)],
            isSigner: false,
            isWritable: true
        });
        accounts[1] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.syntToken)],
            isSigner: false,
            isWritable: true
        });
        accounts[2] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.syntTokenData)],
            isSigner: false,
            isWritable: false
        });
        accounts[3] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.txState)],
            isSigner: false,
            isWritable: true
        });
        accounts[4] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.chain2address)],
            isSigner: false,
            isWritable: true
        });
        accounts[5] = SolanaAccountMeta({ pubkey: SOLANA_TOKEN_PROGRAM, isSigner: false, isWritable: false });
        accounts[6] = SolanaAccountMeta({ pubkey: SOLANA_SYSTEM_PROGRAM, isSigner: false, isWritable: false });
        accounts[7] = SolanaAccountMeta({ pubkey: SOLANA_RENT, isSigner: false, isWritable: false });
        accounts[8] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.oppositeBridgeData)],
            isSigner: true,
            isWritable: false
        });

        // TODO add payment by token
        IBridge(bridge).transmitRequestV2ToSolana(
            serializeSolanaStandaloneInstruction(
                SolanaStandaloneInstruction(
                    /* programId: */
                    _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
                    /* accounts: */
                    accounts,
                    /* data: */
                    abi.encodePacked(sighashMintSyntheticToken, txID, _txStateBump, solAmount)
                )
            ),
            _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
            _pubkeys[uint256(SynthesizePubkeys.oppositeBridge)],
            SOLANA_CHAIN_ID,
            txID,
            _msgSender(),
            nonce
        );

        TxState storage txState = requests[txID];
        txState.recipient = castToBytes32(_msgSender());
        txState.chain2address = _pubkeys[uint256(SynthesizePubkeys.chain2address)];
        txState.rtoken = castToBytes32(_token);
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequestSolana(
            txID,
            _msgSender(),
            _pubkeys[uint256(SynthesizePubkeys.chain2address)],
            _amount,
            _token
        );
    }

    /**
     * @dev Synthesize token request with permit.
     * @param _permitData permit data
     * @param _token token address to synthesize
     * @param _amount amount to synthesize
     * @param _chain2address amount recipient address
     * @param _receiveSide request recipient address
     * @param _oppositeBridge opposite bridge address
     * @param _chainID opposite chain ID
     */
    function synthesizeWithPermit(
        PermitData memory _permitData,
        address _token,
        uint256 _amount,
        address _chain2address,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainID
    ) external returns (bytes32 txID) {
        // require(tokenDecimals[castToBytes32(_token)] > 0, "Portal: token must be verified");

        IERC20(_token).permit(
            _msgSender(),
            address(this),
            _permitData.approveMax ? uint256(2**256 - 1) : _amount,
            _permitData.deadline,
            _permitData.v,
            _permitData.r,
            _permitData.s
        );

        TransferHelper.safeTransferFrom(_token, _msgSender(), address(this), _amount);
        balanceOf[_token] += _amount;

        uint256 nonce = IBridge(bridge).getNonce(_msgSender());
        txID = IBridge(bridge).prepareRqId(
            castToBytes32(_oppositeBridge),
            _chainID,
            castToBytes32(_receiveSide),
            castToBytes32(_msgSender()),
            nonce
        );

        bytes memory out = abi.encodeWithSelector(
            bytes4(keccak256(bytes("mintSyntheticToken(bytes32,address,uint256,address)"))),
            txID,
            _token,
            _amount,
            _chain2address
        );
        // TODO add payment by token
        IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainID, txID, _msgSender(), nonce);
        TxState storage txState = requests[txID];
        txState.recipient = castToBytes32(_msgSender());
        txState.chain2address = castToBytes32(_chain2address);
        txState.rtoken = castToBytes32(_token);
        txState.amount = _amount;
        txState.state = RequestState.Sent;

        emit SynthesizeRequest(txID, _msgSender(), _chain2address, _amount, _token);
    }

    /**
     * @dev Emergency unsynthesize request. Can be called only by bridge after initiation on a second chain
     * @param _txID transaction ID to unsynth
     */
    function emergencyUnsynthesize(bytes32 _txID) external onlyBridge {
        TxState storage txState = requests[_txID];
        require(txState.state == RequestState.Sent, "Portal: state not open or tx does not exist");

        txState.state = RequestState.Reverted;
        TransferHelper.safeTransfer(castToAddress(txState.rtoken), castToAddress(txState.recipient), txState.amount);

        emit RevertSynthesizeCompleted(
            _txID,
            castToAddress(txState.recipient),
            txState.amount,
            castToAddress(txState.rtoken)
        );
    }

    /**
     * @dev Unsynthesize request. Can be called only by bridge after initiation on a second chain
     * @param _txID transaction ID to unsynth
     * @param _token token address to unsynth
     * @param _amount amount to unsynth
     * @param _to recipient address
     */
    function unsynthesize(
        bytes32 _txID,
        address _token,
        uint256 _amount,
        address _to
    ) external onlyBridge {
        require(unsynthesizeStates[_txID] == UnsynthesizeState.Default, "Portal: synthetic tokens emergencyUnburn");
        TransferHelper.safeTransfer(_token, _to, _amount);
        balanceOf[_token] -= _amount;
        unsynthesizeStates[_txID] = UnsynthesizeState.Unsynthesized;
        emit BurnCompleted(_txID, _to, _amount, _token);
    }

    /**
     * @dev Revert burnSyntheticToken() operation, can be called several times.
     * @param _txID transaction ID to unburn
     * @param _receiveSide receiver contract address
     * @param _oppositeBridge opposite bridge address
     * @param _chainId opposite chain ID
     */
    function emergencyUnburnRequest(
        bytes32 _txID,
        address _receiveSide,
        address _oppositeBridge,
        uint256 _chainId
    ) external {
        require(unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized, "Portal: real tokens already transferred");
        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        bytes memory out = abi.encodeWithSelector(bytes4(keccak256(bytes("emergencyUnburn(bytes32)"))), _txID);
        // TODO add payment by token
        uint256 nonce = IBridge(bridge).getNonce(_msgSender());
        bytes32 txID = IBridge(bridge).prepareRqId(
            castToBytes32(_oppositeBridge),
            _chainId,
            castToBytes32(_receiveSide),
            castToBytes32(_msgSender()),
            nonce
        );
        IBridge(bridge).transmitRequestV2(out, _receiveSide, _oppositeBridge, _chainId, txID, _msgSender(), nonce);

        emit RevertBurnRequest(txID, _msgSender());
    }

    /**
     * @dev Revert burnSyntheticToken() operation with bytes32 support for Solana. Can be called several times.
     * @param _txID transaction ID to unburn
     * @param _pubkeys unsynth data for Solana
     * @param _chainId opposite chain ID
     */
    function emergencyUnburnRequestToSolana(
        bytes32 _txID,
        bytes32[] calldata _pubkeys,
        uint256 _chainId
    ) external {
        require(_chainId == SOLANA_CHAIN_ID, "Portal: incorrect chainID");
        require(unsynthesizeStates[_txID] != UnsynthesizeState.Unsynthesized, "Portal: real tokens already transferred");

        unsynthesizeStates[_txID] = UnsynthesizeState.RevertRequest;

        uint256 nonce = IBridge(bridge).getNonce(_msgSender());
        bytes32 txID = IBridge(bridge).prepareRqId(
            _pubkeys[uint256(SynthesizePubkeys.oppositeBridge)],
            SOLANA_CHAIN_ID,
            _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
            castToBytes32(_msgSender()),
            nonce
        );

        SolanaAccountMeta[] memory accounts = new SolanaAccountMeta[](7);
        accounts[0] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.receiveSideData)],
            isSigner: false,
            isWritable: false
        });
        accounts[1] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.txState)],
            isSigner: false,
            isWritable: true
        });
        accounts[2] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.syntToken)],
            isSigner: false,
            isWritable: true
        });
        accounts[3] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.syntTokenData)],
            isSigner: false,
            isWritable: false
        });
        accounts[4] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.chain2address)],
            isSigner: false,
            isWritable: true
        });
        accounts[5] = SolanaAccountMeta({ pubkey: SOLANA_TOKEN_PROGRAM, isSigner: false, isWritable: false });
        accounts[6] = SolanaAccountMeta({
            pubkey: _pubkeys[uint256(SynthesizePubkeys.oppositeBridgeData)],
            isSigner: true,
            isWritable: false
        });

        // TODO add payment by token
        IBridge(bridge).transmitRequestV2ToSolana(
            serializeSolanaStandaloneInstruction(
                SolanaStandaloneInstruction(
                    /* programId: */
                    _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
                    /* accounts: */
                    accounts,
                    /* data: */
                    abi.encodePacked(sighashEmergencyUnburn)
                )
            ),
            _pubkeys[uint256(SynthesizePubkeys.receiveSide)],
            _pubkeys[uint256(SynthesizePubkeys.oppositeBridge)],
            SOLANA_CHAIN_ID,
            txID,
            _msgSender(),
            nonce
        );

        emit RevertBurnRequest(txID, _msgSender());
    }

    // should be restricted in mainnets (test only)
    function changeBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
    }

    function createRepresentationRequest(address _rtoken) external {
        emit RepresentationRequest(_rtoken);
    }

    // implies manual verification point
    function approveRepresentationRequest(
        bytes32 _rtoken,
        uint8 _decimals /**onlyOwner */
    ) external {
        tokenDecimals[_rtoken] = _decimals;
        emit ApprovedRepresentationRequest(_rtoken);
    }

    //TODO
    function setProxyCurve(address _proxy) external onlyOwner {
        proxy = _proxy;
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        return _setTrustedForwarder(_forwarder);
    }

    //TODO: revisit memory location and logic in general (may need to use a single case scenario only)
    function synthesize_batch_transit(
        address[] memory _tokens,
        uint256[] memory _amounts, // set a positive amount in order to initiate a synthesize request
        SynthParams memory _synth_params,
        bytes4 _selector,
        bytes calldata _transit_data,
        PermitData[] memory _permit_data
    ) external {
        bytes32[] memory txId = new bytes32[](_tokens.length);

        //synthesize request
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_amounts[i] > 0) {
                // require(tokenDecimals[castToBytes32(_token)[i]] > 0, "Portal: token must be verified");
                if (_permit_data[i].v != 0) {
                    uint256 approve_value = _permit_data[i].approveMax ? uint256(2**256 - 1) : _amounts[i];
                    IERC20(_tokens[i]).permit(
                        _msgSender(),
                        address(this),
                        approve_value,
                        _permit_data[i].deadline,
                        _permit_data[i].v,
                        _permit_data[i].r,
                        _permit_data[i].s
                    );
                }
                TransferHelper.safeTransferFrom(_tokens[i], _msgSender(), address(this), _amounts[i]);

                balanceOf[_tokens[i]] += _amounts[i];
                uint256 nonce = IBridge(bridge).getNonce(_msgSender());

                txId[i] = keccak256(
                    abi.encodePacked(
                        IBridge(bridge).prepareRqId(
                            castToBytes32(_synth_params.oppositeBridge),
                            _synth_params.chainID,
                            castToBytes32(_synth_params.receiveSide),
                            castToBytes32(_msgSender()),
                            nonce
                        ),
                        i
                    )
                );

                // TODO add payment by token
                TxState storage txState = requests[txId[i]];
                txState.recipient = castToBytes32(_msgSender()); //change!
                txState.chain2address = castToBytes32(_synth_params.chain2address);
                txState.rtoken = castToBytes32(_tokens[i]);
                txState.amount = _amounts[i];
                txState.state = RequestState.Sent;

                emit SynthesizeRequest(txId[i], _msgSender(), _synth_params.chain2address, _amounts[i], _tokens[i]);
            }
        }

        // encode call
        bytes memory out = abi.encodePacked(
            _selector,
            _transit_data,
            //////////////
            _tokens,
            _amounts,
            txId
        );

        uint256 general_nonce = IBridge(bridge).getNonce(_msgSender());
        bytes32 general_txId = IBridge(bridge).prepareRqId(
            castToBytes32(_synth_params.oppositeBridge),
            _synth_params.chainID,
            castToBytes32(_synth_params.receiveSide),
            castToBytes32(_msgSender()),
            general_nonce
        );

        IBridge(bridge).transmitRequestV2(
            out,
            _synth_params.receiveSide,
            _synth_params.oppositeBridge,
            _synth_params.chainID,
            general_txId,
            _msgSender(),
            general_nonce
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBridge {
     function transmitRequestV2(bytes memory owner, address receiveSide, address oppositeBridge, uint chainID, bytes32 requestId, address sender, uint256 nonce) external returns (bool);
     function transmitRequestV2ToSolana(bytes memory owner, bytes32 receiveSide, bytes32 oppositeBridge, uint chainID, bytes32 requestId, address sender, uint256 nonce) external returns (bool);
     function prepareRqId(bytes32 oppositeBridge, uint256 chainId, bytes32 receiveSide, bytes32 from, uint256 nonce) external view returns (bytes32);
     function getNonce(address from) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract RelayRecipient is ContextUpgradeable, OwnableUpgradeable {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract SolanaSerialize {
    // Solana constants
    uint256 public constant SOLANA_CHAIN_ID = 501501501;
    // base58: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
    bytes32 public constant SOLANA_TOKEN_PROGRAM = 0x06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9;
    // base58: 11111111111111111111111111111111
    bytes32 public constant SOLANA_SYSTEM_PROGRAM = 0x0;
    // base58: SysvarRent111111111111111111111111111111111
    bytes32 public constant SOLANA_RENT = 0x06a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a00000000;

    struct SolanaAccountMeta {
        bytes32 pubkey;
        bool isSigner;
        bool isWritable;
    }

    struct SolanaStandaloneInstruction {
        bytes32 programId;
        SolanaAccountMeta[] accounts;
        bytes data;
    }

    function serializeSolanaStandaloneInstruction(SolanaStandaloneInstruction memory ix)
        public
        pure
        returns (
            bytes memory /* data */
        )
    {
        uint32 _len = uint32(ix.accounts.length);
        // swap bytes
        _len = ((_len & 0xFF00FF00) >> 8) | ((_len & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        _len = (_len >> 16) | (_len << 16);

        bytes memory _data = abi.encodePacked(_len);
        bytes memory _d;
        for (uint256 i = 0; i < ix.accounts.length; i++) {
            _d = abi.encodePacked(ix.accounts[i].pubkey, ix.accounts[i].isSigner, ix.accounts[i].isWritable);
            _data = abi.encodePacked(_data, _d);
        }

        _data = abi.encodePacked(_data, ix.programId);

        _len = uint32(ix.data.length);
        // swap bytes
        _len = ((_len & 0xFF00FF00) >> 8) | ((_len & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        _len = (_len >> 16) | (_len << 16);

        _data = abi.encodePacked(_data, _len);
        _data = abi.encodePacked(_data, ix.data);

        return (_data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract Typecast {
    function castToAddress(bytes32 x) public pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function castToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}