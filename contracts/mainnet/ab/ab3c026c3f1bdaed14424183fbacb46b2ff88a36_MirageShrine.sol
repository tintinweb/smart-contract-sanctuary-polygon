// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.10;

interface IBalanceHolder {
  function withdraw (  ) external;
  function balanceOf ( address ) external view returns ( uint256 );
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.10;

import './IBalanceHolder.sol';

interface IRealityETH is IBalanceHolder {
     event LogAnswerReveal (bytes32 indexed question_id, address indexed user, bytes32 indexed answer_hash, bytes32 answer, uint256 nonce, uint256 bond);
     event LogCancelArbitration (bytes32 indexed question_id);
     event LogClaim (bytes32 indexed question_id, address indexed user, uint256 amount);
     event LogFinalize (bytes32 indexed question_id, bytes32 indexed answer);
     event LogFundAnswerBounty (bytes32 indexed question_id, uint256 bounty_added, uint256 bounty, address indexed user);
     event LogMinimumBond (bytes32 indexed question_id, uint256 min_bond);
     event LogNewAnswer (bytes32 answer, bytes32 indexed question_id, bytes32 history_hash, address indexed user, uint256 bond, uint256 ts, bool is_commitment);
     event LogNewQuestion (bytes32 indexed question_id, address indexed user, uint256 template_id, string question, bytes32 indexed content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 created);
     event LogNewTemplate (uint256 indexed template_id, address indexed user, string question_text);
     event LogNotifyOfArbitrationRequest (bytes32 indexed question_id, address indexed user);
     event LogReopenQuestion (bytes32 indexed question_id, bytes32 indexed reopened_question_id);
     event LogSetQuestionFee (address arbitrator, uint256 amount);

     function assignWinnerAndSubmitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address payee_if_wrong, bytes32 last_history_hash, bytes32 last_answer_or_commitment_id, address last_answerer) external;
     function cancelArbitration (bytes32 question_id) external;
     function claimMultipleAndWithdrawBalance (bytes32[] calldata question_ids, uint256[] calldata lengths, bytes32[] calldata hist_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function claimWinnings (bytes32 question_id, bytes32[] calldata history_hashes, address[] calldata addrs, uint256[] calldata bonds, bytes32[] calldata answers) external;
     function createTemplate (string calldata content) external returns (uint256);
     function notifyOfArbitrationRequest (bytes32 question_id, address requester, uint256 max_previous) external;
     function setQuestionFee (uint256 fee) external;
     function submitAnswerByArbitrator (bytes32 question_id, bytes32 answer, address answerer) external;
     function submitAnswerReveal (bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond) external;
     function askQuestion (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
     function askQuestionWithMinBond (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond) external payable returns (bytes32);
     function createTemplateAndAskQuestion (string calldata content, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
     function fundAnswerBounty (bytes32 question_id) external payable;
     function reopenQuestion (uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 min_bond, bytes32 reopens_question_id) external payable returns (bytes32);
     function submitAnswer (bytes32 question_id, bytes32 answer, uint256 max_previous) external payable;
     function submitAnswerCommitment (bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer) external payable;
     function submitAnswerFor (bytes32 question_id, bytes32 answer, uint256 max_previous, address answerer) external payable;
     function arbitrator_question_fees (address) external view returns (uint256);
     function commitments (bytes32) external view returns (uint32 reveal_ts, bool is_revealed, bytes32 revealed_answer);
     function getArbitrator (bytes32 question_id) external view returns (address);
     function getBestAnswer (bytes32 question_id) external view returns (bytes32);
     function getBond (bytes32 question_id) external view returns (uint256);
     function getBounty (bytes32 question_id) external view returns (uint256);
     function getContentHash (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswer (bytes32 question_id) external view returns (bytes32);
     function getFinalAnswerIfMatches (bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond) external view returns (bytes32);
     function getFinalizeTS (bytes32 question_id) external view returns (uint32);
     function getHistoryHash (bytes32 question_id) external view returns (bytes32);
     function getMinBond (bytes32 question_id) external view returns (uint256);
     function getOpeningTS (bytes32 question_id) external view returns (uint32);
     function getTimeout (bytes32 question_id) external view returns (uint32);
     function isFinalized (bytes32 question_id) external view returns (bool);
     function isPendingArbitration (bytes32 question_id) external view returns (bool);
     function isSettledTooSoon (bytes32 question_id) external view returns (bool);
     function question_claims (bytes32) external view returns (address payee, uint256 last_bond, uint256 queued_funds);
     function questions (bytes32) external view returns (bytes32 content_hash, address arbitrator, uint32 opening_ts, uint32 timeout, uint32 finalize_ts, bool is_pending_arbitration, uint256 bounty, bytes32 best_answer, bytes32 history_hash, uint256 bond, uint256 min_bond);
     function reopened_questions (bytes32) external view returns (bytes32);
     function reopener_questions (bytes32) external view returns (bool);
     function resultFor (bytes32 question_id) external view returns (bytes32);
     function resultForOnceSettled (bytes32 question_id) external view returns (bytes32);
     function template_hashes (uint256) external view returns (bytes32);
     function templates (uint256) external view returns (uint256);
}

// SPDX-License-Identifier: Mirage Shrine Vow

// This scroll grants you the power to wield this creation as you see fit.
// Be warned, the winds of fate may turn against those who misuse it.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./MirageShrine.sol";
import "./Stringer.sol";

contract Fate is IERC20Metadata {
    struct Info {
        bytes23 rune;
        uint64 prophecyId;
        bool yes;
    }

    MirageShrine immutable public SHRINE;
    address constant internal PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    Info public info;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) internal allowanceOf;

    modifier onlyShrine {
        require(msg.sender == address(SHRINE), "Begone, unholy spirits");
        _;
    }

    constructor (MirageShrine shrine) {
        SHRINE = shrine;
    }

    // Have faith in the Shrine. Names are powerful things.
    function initialize(bytes23 rune, uint64 id, bool yes) external onlyShrine {
        info.rune = rune;
        info.prophecyId = id;
        info.yes = yes;
    }

    // Fate will lose count when the time comes.
    function totalSupply() external view returns (uint256) {
        (, , , , , uint256 supply,) = SHRINE.prophecies(info.prophecyId);
        return (supply);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowanceOf[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return (true);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        if (spender == PERMIT2) {
            return (type(uint256).max);
        } else {
            return (allowanceOf[owner][spender]);
        }
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (msg.sender != PERMIT2) {
            allowanceOf[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Let the different realms flourish.
    function mint(address to, uint256 amount) external onlyShrine {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Crystallize, become matter!
    function burn(address from, uint256 amount) external onlyShrine {
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function decimals() external view returns(uint8) {
        (IERC20Metadata essence, , , , , ,) = SHRINE.prophecies(info.prophecyId);
        return essence.decimals();
    }

    // YES Lemon Fate
    // NO Lemon Fate
    function name() public view returns(string memory) {
        return string(abi.encodePacked(
            info.yes ? "YES" : "NO",
            Stringer.bytes23ToString(info.rune),
            " Fate"
        ));
    }

    // Y:Lemon=WETH
    // N:Lemon=WETH
    function symbol() external view returns(string memory) {
        (IERC20Metadata essence, , , , , ,) = SHRINE.prophecies(info.prophecyId);
        return string(abi.encodePacked(
            info.yes ? "Y:" : "N:",
            Stringer.bytes23ToString(bytes23(bytes6(info.rune))),
            "=",
            essence.symbol()
        ));
    }
}

// SPDX-License-Identifier: Mirage Shrine Vow

// This scroll grants you the power to wield this creation as you see fit.
// Be warned, the winds of fate may turn against those who misuse it.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@reality.eth/contracts/development/contracts/IRealityETH.sol";
import "./Fate.sol";

contract MirageShrine {

    enum Aura {
        Forthcoming,
        Blighted,
        Reality,
        Mirage
    }

    struct Prophecy {
        IERC20Metadata essence;
        uint32 horizon;
        Aura aura;
        //
        Fate no;
        //
        Fate yes;
        //
        uint256 fateSupply;
        //
        bytes32 inquiryId;
    }

    event Offering(address donor, uint256 amount);
    // Prophecy data is meant to remain, no need to proclaim it.
    event Scry(uint64 indexed prophecyId, address indexed essence);
    // No utility has been found in celebrating distillments and blendings.
    // The shrine does not indulge in vanity. 
    event Emergence(uint64 indexed prophecyId, Aura indexed aura);

    address immutable mirager;
    address immutable fateMonument;
    IRealityETH immutable reality;
    uint256 immutable templateId;
    uint256 immutable tribute;
    uint256 immutable minBond;
    address immutable arbitrator;

    bytes32 constant NO = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant YES = 0x0000000000000000000000000000000000000000000000000000000000000001;

    Prophecy[] public prophecies;

    constructor (IRealityETH _reality, address _fateMonument, uint256 _templateId, address _arbitrator,  uint256 _tribute, uint256 _minBond) {
        mirager = msg.sender;
        reality = _reality;
        fateMonument = _fateMonument;
        templateId = _templateId;
        arbitrator = _arbitrator;
        tribute = _tribute;
        minBond = _minBond;
    }

    receive() external payable {
        emit Offering(msg.sender, msg.value);
    }

    function relayOffering() external {
        payable(mirager).transfer(address(this).balance);
    }

    function deployFate() internal returns (address result) {
        bytes20 fateAt = bytes20(fateMonument);
        assembly ("memory-safe") {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), fateAt)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function scry(uint32 _horizon, IERC20Metadata _essence, bytes23 _rune, string calldata _inquiry) external payable returns (uint64 id) {
        require(msg.value >= tribute, "Leave a coin to honor the divine");
        emit Offering(msg.sender, msg.value);
        require(block.timestamp < _horizon);
        id = uint64(prophecies.length);
        emit Scry(id, address(_essence));
    
        Prophecy storage prophecy = prophecies.push();
        prophecy.essence = _essence;
        prophecy.horizon = _horizon;
        prophecy.inquiryId = reality.askQuestionWithMinBond(
            templateId,
            _inquiry,
            arbitrator,
            2 days,
            _horizon,
            0,
            minBond
        );

        // deploying minimal proxy is ~40k.
        prophecy.yes = Fate(deployFate());
        // initializing is ~20k (+ delegate)
        prophecy.yes.initialize(_rune, id, true);
        prophecy.no = Fate(deployFate());
        prophecy.no.initialize(_rune, id, false);
    }

    function distill(uint64 _prophecy, uint256 _amount) external {
        Prophecy storage prophecy = prophecies[_prophecy];
        require(prophecy.essence.transferFrom(msg.sender, address(this), _amount));
        require(block.timestamp < prophecy.horizon, "Alas! The essence defied decouplement!");

        prophecy.yes.mint(msg.sender, _amount);
        prophecy.no.mint(msg.sender, _amount);
        prophecy.fateSupply += _amount;
    }

    function blend(uint64 _prophecy, uint256 _amount) external {
        Prophecy storage prophecy = prophecies[_prophecy];
        require(block.timestamp < prophecy.horizon, "The fates repel each other!");

        prophecy.yes.burn(msg.sender, _amount);
        prophecy.no.burn(msg.sender, _amount);

        prophecy.essence.transfer(msg.sender, _amount);
        prophecy.fateSupply -= _amount;
    }

    function ascend(uint64 _prophecy) external {
        Prophecy storage prophecy = prophecies[_prophecy];
        if (prophecy.aura == Aura.Forthcoming) {
            // If truth has not arrived, halt!
            bytes32 truth = reality.resultFor(prophecy.inquiryId);

            if (truth == NO) {
                // Destiny is elusive.
                prophecy.aura = Aura.Mirage;
            } else if (truth == YES) {
                // As predicted by the Shrine.
                prophecy.aura = Aura.Reality;
            } else {
                // Fool! You were told not to bring certainty to the profane.
                prophecy.aura = Aura.Blighted;
                prophecy.essence.transfer(mirager, prophecy.fateSupply);
            }
            emit Emergence(_prophecy, prophecy.aura);
            if (prophecy.aura == Aura.Blighted) return();
        }
        
        Fate fate;
        if (prophecy.aura == Aura.Mirage) {
            fate = prophecy.no;
        } else if (prophecy.aura == Aura.Reality) {
            fate = prophecy.yes;
        } else {
            // Depart from this holy site.
            revert();
        }

        uint256 grace = fate.balanceOf(msg.sender);
        fate.burn(msg.sender, grace);
        prophecy.essence.transfer(msg.sender, grace);
    }

    function count() external view returns(uint256) {
        return prophecies.length;
    }
}

// SPDX-License-Identifier: Mirage Shrine Vow

// This scroll grants you the power to wield this creation as you see fit.
// Be warned, the winds of fate may turn against those who misuse it.

pragma solidity ^0.8.19;

library Stringer {
    function bytes23ToString(bytes23 _x) internal pure returns (string memory) {
        unchecked {
            bytes memory bytesString = new bytes(23);
            uint charCount = 0;
            for (uint j = 0; j < 23; j++) {
                bytes1 currentChar = bytes1(_x << (8 * j));
                if (currentChar != 0) {
                    bytesString[charCount] = currentChar;
                    charCount++;
                } else {
                    break;
                }
            }
            bytes memory bytesStringTrimmed = new bytes(charCount);
            for (uint j = 0; j < charCount; j++) {
                bytesStringTrimmed[j] = bytesString[j];
            }
            return string(bytesStringTrimmed);
        }
    }
}