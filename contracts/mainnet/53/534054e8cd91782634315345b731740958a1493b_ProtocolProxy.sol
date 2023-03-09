//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface API {
    struct Token {
        string ipfsHash;
        address[] contractAddresses;
        uint256 id;
        address[] totalSupply;
        address[] excludedFromCirculation;
        uint256 lastUpdate;
        uint256 utilityScore;
        uint256 socialScore;
        uint256 trustScore;
    }

    function addAssetData(Token memory token) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

struct SubmitQuery {
    string ipfsHash;
    address[] contractAddresses;
    uint256 id;
    address[] totalSupply;
    address[] excludedFromCirculation;
    uint256 lastUpdate;
    uint256 utilityScore;
    uint256 socialScore;
    uint256 trustScore;
    uint256 coeff;
}

contract ProtocolProxy is Initializable {
    address public owner;
    uint256 public submitFloorPrice;

    uint256 public firstSortMaxVotes;
    uint256 public firstSortValidationsNeeded;
    uint256 public finalDecisionValidationsNeeded;
    uint256 public finalDecisionMaxVotes;
    uint256 public tokensPerVote;

    uint256 public membersToPromoteToRankI;
    uint256 public membersToPromoteToRankII;
    uint256 public votesNeededToRankIPromotion;
    uint256 public votesNeededToRankIIPromotion;
    uint256 public membersToDemoteFromRankI;
    uint256 public membersToDemoteFromRankII;
    uint256 public votesNeededToRankIDemotion;
    uint256 public votesNeededToRankIIDemotion;
    uint256 public voteCooldown;

    mapping(address => bool) public whitelistedStable;

    mapping(address => mapping(uint256 => bool)) public firstSortVotes;
    mapping(address => mapping(uint256 => bool)) public finalDecisionVotes;
    mapping(uint256 => address[]) public tokenFirstValidations;
    mapping(uint256 => address[]) public tokenFirstRejections;
    mapping(uint256 => address[]) public tokenFinalValidations;
    mapping(uint256 => address[]) public tokenFinalRejections;

    mapping(uint256 => uint256[]) public tokenUtilityScore;
    mapping(uint256 => uint256[]) public tokenSocialScore;
    mapping(uint256 => uint256[]) public tokenTrustScore;

    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodFirstVotes;
    mapping(address => uint256) public badFirstVotes;
    mapping(address => uint256) public badFinalVotes;
    mapping(address => uint256) public goodFinalVotes;
    mapping(address => uint256) public owedRewards;
    mapping(address => uint256) public paidRewards;

    SubmitQuery[] public submittedTokens;

    SubmitQuery[] public firstSortTokens;
    mapping(uint256 => uint256) public indexOfFirstSortTokens;
    SubmitQuery[] public finalValidationTokens;
    mapping(uint256 => uint256) public indexOfFinalValidationTokens;

    IERC20 MOBL;
    API ProtocolAPI;

    event DataSubmitted(SubmitQuery token);
    event FirstSortVote(
        SubmitQuery token,
        address voter,
        bool validated,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    );
    event FinalValidationVote(
        SubmitQuery token,
        address voter,
        bool validated,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    );
    event FirstSortValidated(SubmitQuery token, uint256 validations);
    event FirstSortRejected(SubmitQuery token, uint256 validations);
    event FinalDecisionValidated(SubmitQuery token, uint256 validations);
    event FinalDecisionRejected(SubmitQuery token, uint256 validations);

    function initialize(address _owner, address _mobulaTokenAddress)
        public
        initializer
    {
        owner = _owner;
        MOBL = IERC20(_mobulaTokenAddress);
    }

    // Getters for public arrays

    function getSubmittedTokens() external view returns (SubmitQuery[] memory) {
        return submittedTokens;
    }

    function getFirstSortTokens() external view returns (SubmitQuery[] memory) {
        return firstSortTokens;
    }

    function getFinalValidationTokens()
        external
        view
        returns (SubmitQuery[] memory)
    {
        return finalValidationTokens;
    }

    //Protocol variables updaters

    function changeWhitelistedStable(address _stableAddress) external {
        require(owner == msg.sender, "DAO Only");
        whitelistedStable[_stableAddress] = !whitelistedStable[_stableAddress];
    }

    function updateProtocolAPIAddress(address _protocolAPIAddress) external {
        require(owner == msg.sender, "DAO Only");
        ProtocolAPI = API(_protocolAPIAddress);
    }

    function updateSubmitFloorPrice(uint256 _submitFloorPrice) external {
        require(owner == msg.sender, "DAO Only");
        submitFloorPrice = _submitFloorPrice;
    }

    function updateFirstSortMaxVotes(uint256 _firstSortMaxVotes) external {
        require(owner == msg.sender, "DAO Only");
        firstSortMaxVotes = _firstSortMaxVotes;
    }

    function updateFinalDecisionMaxVotes(uint256 _finalDecisionMaxVotes)
        external
    {
        require(owner == msg.sender, "DAO Only");
        finalDecisionMaxVotes = _finalDecisionMaxVotes;
    }

    function updateFirstSortValidationsNeeded(
        uint256 _firstSortValidationsNeeded
    ) external {
        require(owner == msg.sender, "DAO Only");
        firstSortValidationsNeeded = _firstSortValidationsNeeded;
    }

    function updateFinalDecisionValidationsNeeded(
        uint256 _finalDecisionValidationsNeeded
    ) external {
        require(owner == msg.sender, "DAO Only");
        finalDecisionValidationsNeeded = _finalDecisionValidationsNeeded;
    }

    function updateTokensPerVote(uint256 _tokensPerVote) external {
        require(owner == msg.sender, "DAO Only");
        tokensPerVote = _tokensPerVote;
    }

    function updateMembersToPromoteToRankI(uint256 _membersToPromoteToRankI)
        external
    {
        require(owner == msg.sender, "DAO Only");
        membersToPromoteToRankI = _membersToPromoteToRankI;
    }

    function updateMembersToPromoteToRankII(uint256 _membersToPromoteToRankII)
        external
    {
        require(owner == msg.sender, "DAO Only");
        membersToPromoteToRankII = _membersToPromoteToRankII;
    }

    function updateMembersToDemoteFromRankI(uint256 _membersToDemoteToRankI)
        external
    {
        require(owner == msg.sender, "DAO Only");
        membersToDemoteFromRankI = _membersToDemoteToRankI;
    }

    function updateMembersToDemoteFromRankII(uint256 _membersToDemoteToRankII)
        external
    {
        require(owner == msg.sender, "DAO Only");
        membersToDemoteFromRankII = _membersToDemoteToRankII;
    }

    function updateVotesNeededToRankIPromotion(
        uint256 _votesNeededToRankIPromotion
    ) external {
        require(owner == msg.sender, "DAO Only");
        votesNeededToRankIPromotion = _votesNeededToRankIPromotion;
    }

    function updateVotesNeededToRankIIPromotion(
        uint256 _votesNeededToRankIIPromotion
    ) external {
        require(owner == msg.sender, "DAO Only");
        votesNeededToRankIIPromotion = _votesNeededToRankIIPromotion;
    }

    function updateVotesNeededToRankIDemotion(
        uint256 _votesNeededToRankIDemotion
    ) external {
        require(owner == msg.sender, "DAO Only");
        votesNeededToRankIDemotion = _votesNeededToRankIDemotion;
    }

    function updateVotesNeededToRankIIDemotion(
        uint256 _votesNeededToRankIIDemotion
    ) external {
        require(owner == msg.sender, "DAO Only");
        votesNeededToRankIIDemotion = _votesNeededToRankIIDemotion;
    }

    function updateVoteCooldown(uint256 _voteCooldown) external {
        require(owner == msg.sender, "DAO Only");
        voteCooldown = _voteCooldown;
    }

    //Protocol data processing

    function submitIPFS(
        address[] memory contractAddresses,
        address[] memory totalSupplyAddresses,
        address[] memory excludedCirculationAddresses,
        string memory ipfsHash,
        address paymentTokenAddress,
        uint256 paymentAmount,
        uint256 assetId
    ) external payable {
        require(
            whitelistedStable[paymentTokenAddress],
            "You must pay with valid stable."
        );
        require(
            contractAddresses.length > 0,
            "You must submit at least one contract."
        );
        require(
            paymentAmount >= submitFloorPrice,
            "You must pay the required amount."
        );

        IERC20 paymentToken = IERC20(paymentTokenAddress);

        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                paymentAmount * 10**paymentToken.decimals(),
            "You must approve the required amount."
        );
        require(
            paymentToken.transferFrom(
                msg.sender,
                address(this),
                paymentAmount * 10**paymentToken.decimals()
            ),
            "Payment failed."
        );

        for (uint256 i = 0; i < firstSortTokens.length; i++) {
            for (
                uint256 j = 0;
                j < firstSortTokens[i].contractAddresses.length;
                j++
            ) {
                for (uint256 k = 0; k < contractAddresses.length; k++) {
                    require(
                        firstSortTokens[i].contractAddresses[j] !=
                            contractAddresses[k],
                        "One of the smart-contracts is already in the listing process."
                    );
                }
            }
        }

        for (uint256 i = 0; i < finalValidationTokens.length; i++) {
            for (
                uint256 j = 0;
                j < finalValidationTokens[i].contractAddresses.length;
                j++
            ) {
                for (uint256 k = 0; k < contractAddresses.length; k++) {
                    require(
                        finalValidationTokens[i].contractAddresses[j] !=
                            contractAddresses[k],
                        "One of the smart-contracts is already in the listing process."
                    );
                }
            }
        }

        uint256 finalId;

        if (assetId == 0) {
            finalId = submittedTokens.length;
        } else {
            finalId = assetId;
        }

        SubmitQuery memory submittedToken = SubmitQuery(
            ipfsHash,
            contractAddresses,
            finalId,
            totalSupplyAddresses,
            excludedCirculationAddresses,
            block.timestamp,
            0,
            0,
            0,
            (paymentAmount * 1000) / submitFloorPrice
        );

        submittedTokens.push(submittedToken);
        indexOfFirstSortTokens[submittedToken.id] = firstSortTokens.length;
        firstSortTokens.push(submittedToken);
        emit DataSubmitted(submittedToken);
    }

    function firstSortVote(
        uint256 tokenId,
        bool validate,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    ) external {
        require(rank[msg.sender] >= 1, "You must be Rank I or higher to vote.");
        require(
            firstSortTokens[indexOfFirstSortTokens[tokenId]]
                .contractAddresses
                .length > 0,
            "Token not submitted."
        );
        require(
            !firstSortVotes[msg.sender][tokenId],
            "You cannot vote twice for the same token."
        );
        require(
            block.timestamp >
                firstSortTokens[indexOfFirstSortTokens[tokenId]].lastUpdate +
                    voteCooldown,
            "You must wait before the end of the cooldown to vote."
        );
        require(
            utilityScore <= 5 && socialScore <= 5 && trustScore <= 5,
            "Scores must be between 0 and 5."
        );

        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);

        firstSortVotes[msg.sender][tokenId] = true;

        if (validate) {
            tokenFirstValidations[tokenId].push(msg.sender);
        } else {
            tokenFirstRejections[tokenId].push(msg.sender);
        }

        emit FirstSortVote(
            firstSortTokens[indexOfFirstSortTokens[tokenId]],
            msg.sender,
            validate,
            utilityScore,
            socialScore,
            trustScore
        );

        if (
            tokenFirstValidations[tokenId].length +
                tokenFirstRejections[tokenId].length >=
            firstSortMaxVotes
        ) {
            if (
                tokenFirstValidations[tokenId].length >=
                firstSortValidationsNeeded
            ) {
                indexOfFinalValidationTokens[tokenId] = finalValidationTokens
                    .length;
                finalValidationTokens.push(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]]
                );
                emit FirstSortValidated(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            } else {
                emit FirstSortRejected(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            }

            firstSortTokens[indexOfFirstSortTokens[tokenId]] = firstSortTokens[
                firstSortTokens.length - 1
            ];
            indexOfFirstSortTokens[
                firstSortTokens[firstSortTokens.length - 1].id
            ] = indexOfFirstSortTokens[tokenId];
            firstSortTokens.pop();
        }
    }

    function finalDecisionVote(
        uint256 tokenId,
        bool validate,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    ) external {
        require(rank[msg.sender] >= 2, "You must be Rank II to vote.");
        require(
            finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                .contractAddresses
                .length > 0,
            "Token not submitted."
        );
        require(
            !finalDecisionVotes[msg.sender][tokenId],
            "You cannot vote twice for the same token."
        );

        finalDecisionVotes[msg.sender][tokenId] = true;

        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);

        if (validate) {
            tokenFinalValidations[tokenId].push(msg.sender);
        } else {
            tokenFinalRejections[tokenId].push(msg.sender);
        }

        emit FinalValidationVote(
            finalValidationTokens[indexOfFinalValidationTokens[tokenId]],
            msg.sender,
            validate,
            utilityScore,
            socialScore,
            trustScore
        );

        if (
            tokenFinalValidations[tokenId].length +
                tokenFinalRejections[tokenId].length >=
            finalDecisionMaxVotes
        ) {
            if (
                tokenFinalValidations[tokenId].length >=
                finalDecisionValidationsNeeded
            ) {
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    goodFirstVotes[tokenFirstValidations[tokenId][i]]++;
                    owedRewards[
                        tokenFirstValidations[tokenId][i]
                    ] += finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ].coeff;
                }

                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    badFirstVotes[tokenFirstRejections[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalValidations[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    goodFinalVotes[tokenFinalValidations[tokenId][i]]++;
                    owedRewards[tokenFirstValidations[tokenId][i]] +=
                        finalValidationTokens[
                            indexOfFinalValidationTokens[tokenId]
                        ].coeff *
                        2;
                }

                // Punish wrong final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalRejections[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    badFinalVotes[tokenFinalRejections[tokenId][i]]++;
                }

                uint256 tokenUtilityScoreAverage;

                for (
                    uint256 i = 0;
                    i < tokenUtilityScore[tokenId].length;
                    i++
                ) {
                    tokenUtilityScoreAverage += tokenUtilityScore[tokenId][i];
                }

                tokenUtilityScoreAverage /= tokenUtilityScore[tokenId].length;

                uint256 tokenSocialScoreAverage;

                for (uint256 i = 0; i < tokenSocialScore[tokenId].length; i++) {
                    tokenSocialScoreAverage += tokenSocialScore[tokenId][i];
                }

                tokenSocialScoreAverage /= tokenSocialScore[tokenId].length;

                uint256 tokenTrustScoreAverage;

                for (uint256 i = 0; i < tokenTrustScore[tokenId].length; i++) {
                    tokenTrustScoreAverage += tokenTrustScore[tokenId][i];
                }

                tokenTrustScoreAverage /= tokenTrustScore[tokenId].length;

                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .utilityScore = tokenUtilityScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .socialScore = tokenSocialScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .trustScore = tokenTrustScoreAverage;

                API.Token memory token = API.Token(
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .ipfsHash,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .contractAddresses,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .id,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .totalSupply,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .excludedFromCirculation,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .lastUpdate,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .utilityScore,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .socialScore,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .trustScore
                );

                ProtocolAPI.addAssetData(token);

                emit FinalDecisionValidated(
                    finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ],
                    tokenFinalValidations[tokenId].length
                );
            } else {
                // Punish wrong first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    badFirstVotes[tokenFirstValidations[tokenId][i]]++;
                }

                // Reward good first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    goodFirstVotes[tokenFirstRejections[tokenId][i]]++;
                    owedRewards[
                        tokenFirstValidations[tokenId][i]
                    ] += finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ].coeff;
                }

                // Punish wrong final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalValidations[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    badFinalVotes[tokenFinalValidations[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalRejections[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    goodFinalVotes[tokenFinalRejections[tokenId][i]]++;
                    owedRewards[tokenFirstValidations[tokenId][i]] +=
                        finalValidationTokens[
                            indexOfFinalValidationTokens[tokenId]
                        ].coeff *
                        2;
                }

                emit FinalDecisionRejected(
                    finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ],
                    tokenFinalValidations[tokenId].length
                );
            }

            finalValidationTokens[
                indexOfFinalValidationTokens[tokenId]
            ] = finalValidationTokens[finalValidationTokens.length - 1];
            indexOfFinalValidationTokens[
                finalValidationTokens[finalValidationTokens.length - 1].id
            ] = indexOfFinalValidationTokens[tokenId];
            finalValidationTokens.pop();

            delete tokenUtilityScore[tokenId];
            delete tokenSocialScore[tokenId];
            delete tokenTrustScore[tokenId];
        }
    }

    function claimRewards() external {
        uint256 amountToPay = (owedRewards[msg.sender] -
            paidRewards[msg.sender]) * tokensPerVote;
        require(amountToPay > 0, "Nothing to claim.");
        paidRewards[msg.sender] = owedRewards[msg.sender];
        MOBL.transfer(msg.sender, amountToPay / 1000);
    }

    // Hierarchy management

    function emergencyPromote(address promoted) external {
        require(owner == msg.sender, "DAO Only");
        require(rank[promoted] <= 1, "Impossible");
        rank[promoted]++;
    }

    function emergencyDemote(address demoted) external {
        require(owner == msg.sender, "DAO Only");
        require(rank[demoted] >= 1, "Impossible");
        rank[demoted]--;
    }

    function emergencyKillRequest(uint256 tokenId) external {
        require(owner == msg.sender, "DAO Only");

        for (uint256 i = 0; i < firstSortTokens.length; i++) {
            if (firstSortTokens[i].id == tokenId) {
                firstSortTokens[i] = firstSortTokens[
                    firstSortTokens.length - 1
                ];
                indexOfFirstSortTokens[
                    firstSortTokens[firstSortTokens.length - 1].id
                ] = i;
                firstSortTokens.pop();
                break;
            }
        }

        for (uint256 i = 0; i < finalValidationTokens.length; i++) {
            if (finalValidationTokens[i].id == tokenId) {
                finalValidationTokens[i] = finalValidationTokens[
                    finalValidationTokens.length - 1
                ];
                indexOfFinalValidationTokens[
                    finalValidationTokens[finalValidationTokens.length - 1].id
                ] = i;
                finalValidationTokens.pop();
                break;
            }
        }
    }

    function promote(address promoted) external {
        require(rank[msg.sender] >= 2, "You must be Rank II to promote.");
        require(rank[promoted] <= 1, "Impossible");

        if (rank[promoted] == 0) {
            require(membersToPromoteToRankI > 0, "No promotions yet.");
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                membersToPromoteToRankI--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        } else {
            require(membersToPromoteToRankII > 0, "No promotions yet.");
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIIPromotion) {
                membersToPromoteToRankII--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        }
    }

    function demote(address demoted) external {
        require(rank[msg.sender] >= 2, "You must be Rank II demote.");
        require(rank[demoted] >= 1, "Impossible");

        if (rank[demoted] == 0) {
            require(membersToDemoteFromRankI > 0, "No demotion yet.");
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                membersToDemoteFromRankI--;
                delete demoteVotes[demoted];
                rank[demoted]++;
            }
        } else {
            require(membersToDemoteFromRankII > 0, "No demotion yet.");
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIIDemotion) {
                membersToDemoteFromRankII--;
                delete demoteVotes[demoted];
                rank[demoted]--;
            }
        }
    }

    // Funds management

    function withdrawFunds(uint256 amount) external {
        require(owner == msg.sender, "DAO Only.");
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20Funds(uint256 amount, address contractAddress)
        external
    {
        require(owner == msg.sender, "DAO Only.");
        IERC20 paymentToken = IERC20(contractAddress);
        paymentToken.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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