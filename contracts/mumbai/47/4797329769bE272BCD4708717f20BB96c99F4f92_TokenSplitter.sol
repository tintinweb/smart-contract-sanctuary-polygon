/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface para tokens ERC-20 mais completa
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Interface para tokens ERC-1155 mais completa
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
}

contract TokenSplitter {
    struct Stake {
        uint256 erc20Amount;
        uint256 nftId;
        uint256 balanceSnapshot;
        uint256 startTime;
        uint256 endTime; // Novo campo para armazenar o momento do saque
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;

    uint256 public constant ERC20_SHARE = 6250; // 62.5% dividido para stakers de tokens ERC20
    uint256 public constant NFT_SHARE = 3750;   // 37.5% dividido para stakers com NFT

    address public nftContract; // Endereço do contrato do token NFT
    address public erc20Token;  // Endereço do contrato do token ERC20

    uint256 public rewardsBalance; // Saldo total de tokens de recompensas
    uint256 public rewardsLastDistribution; // Último momento de distribuição das recompensas
    uint256 public rewardsInterval = 5 minutes; // Intervalo de distribuição das recompensas (alterado para 5 minutos)

    address public owner; // Endereço do proprietário do contrato

    event TokensDeposited(address indexed depositor, uint256 erc20Amount, uint256 nftId);
    event TokensWithdrawn(address indexed recipient, uint256 amount, uint256 rewards);
    event NFTRemoved(address indexed recipient, uint256 nftId);
    event StakerRemoved(address indexed staker, uint256 erc20Amount, uint256 nftId);
    event RewardsDeposited(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Just the owner");
        _;
    }

    constructor(address _nftContract, address _erc20Token) {
        nftContract = _nftContract;
        erc20Token = _erc20Token;
        owner = msg.sender; // O criador do contrato é definido como o proprietário
    }

    function depositTokens(uint256 _erc20Amount) external {
        require(_erc20Amount > 0, "Wrong amount");
        require(stakes[msg.sender].nftId == 0, "Its not allowed nft Stakeing");

        IERC20(erc20Token).transferFrom(msg.sender, address(this), _erc20Amount);
        stakes[msg.sender].erc20Amount += _erc20Amount;

        if (balances[msg.sender] == 0) {
            balances[msg.sender] = 1;
        }

        totalBalance += 1;

        emit TokensDeposited(msg.sender, _erc20Amount, 0);
    }

    function depositNFT(uint256 _nftId) external {
        require(IERC1155(nftContract).balanceOf(msg.sender, _nftId) > 0, "thes no NFT IN THE ADRESS");
        require(stakes[msg.sender].nftId == 0, "ITS NOW ALLOED");

        IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), _nftId, 1, "");

        stakes[msg.sender].nftId = _nftId;

        if (balances[msg.sender] == 0) {
            balances[msg.sender] = 1;
        }

        totalBalance += 1;

        emit TokensDeposited(msg.sender, 0, _nftId);
    }

    function withdrawTokens(uint256 _amountToWithdraw) external {
        Stake storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.erc20Amount > 0, "Nenhum token staked");
        require(_amountToWithdraw > 0, "Wrong amount to withdraw");
        require(_amountToWithdraw <= stakeInfo.erc20Amount, "Bigger");

        uint256 erc20ToWithdraw = _amountToWithdraw;
        uint256 rewards = 0;

        // Verificar se o usuário fez o saque antes do período de 5 minutos (rewardsInterval)
        if (stakeInfo.endTime == 0 || block.timestamp >= stakeInfo.endTime + rewardsInterval) {
            // Distribuir as recompensas se necessário
            distributeRewards();

            // Calcular as recompensas proporcionais aos minutos staked
            uint256 minutesStaked = 0;
            if (stakeInfo.endTime > 0) {
                minutesStaked = (block.timestamp - stakeInfo.endTime) / 1 minutes;
            }
            rewards = (rewardsBalance * stakeInfo.erc20Amount * minutesStaked) / (totalBalance * 5 minutes);

            // Atualizar o saldo total de recompensas
            rewardsBalance -= rewards;
        }

        // Atualizar o saldo staked do usuário
        stakeInfo.erc20Amount -= _amountToWithdraw;

        // Transferir os tokens staked e as recompensas para o usuário
        IERC20(erc20Token).transfer(msg.sender, erc20ToWithdraw + rewards);

        // Emitir evento de saque com o valor sacado e as recompensas
        emit TokensWithdrawn(msg.sender, erc20ToWithdraw, rewards);

        // Remover o staker se não tiver mais tokens staked
        if (stakeInfo.erc20Amount == 0) {
            delete stakes[msg.sender];
            balances[msg.sender] = 0;
            totalBalance -= 1;
            emit StakerRemoved(msg.sender, erc20ToWithdraw, 0);
        }
    }

    function withdrawNFT() external {
        Stake storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.nftId > 0, "Nenhum NFT staked");

        uint256 nftIdToWithdraw = stakeInfo.nftId;

        stakeInfo.nftId = 0;
        stakeInfo.balanceSnapshot = 0;
        stakeInfo.startTime = 0;
        stakeInfo.endTime = block.timestamp; // Registrar o momento do saque

        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, nftIdToWithdraw, 1, "");
        emit NFTRemoved(msg.sender, nftIdToWithdraw);
    }

    function hasTokensAndNFTs(address _user) external view returns (string memory) {
        Stake storage stakeInfo = stakes[_user];

        uint256 erc20Balance = IERC20(erc20Token).balanceOf(_user);
        uint256 nftBalance = IERC1155(nftContract).balanceOf(_user, stakeInfo.nftId);

        if (erc20Balance > 0 && nftBalance > 0) {
            return string(abi.encodePacked("Tokens em stake: ", erc20Balance, ", NFTs em stake: ", nftBalance));
        } else {
            return "Thers no stake to this adress";
        }
    }

    function distributeRewards() internal {
        // Verificar se já passou o intervalo de distribuição das recompensas
        if (block.timestamp >= rewardsLastDistribution + rewardsInterval) {
            // Calcular as recompensas a serem distribuídas
            uint256 rewardsToDistribute = IERC20(erc20Token).balanceOf(address(this));

            // Atualizar o saldo total de recompensas
            rewardsBalance = rewardsToDistribute;

            // Atualizar o momento da última distribuição
            rewardsLastDistribution = block.timestamp;
        }
    }

    function depositRewards(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(erc20Token).transferFrom(msg.sender, address(this), _amount);
        rewardsBalance += _amount;
        emit RewardsDeposited(_amount);
    }
}