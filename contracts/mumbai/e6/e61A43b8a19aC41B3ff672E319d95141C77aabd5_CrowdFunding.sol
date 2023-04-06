// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding { 

    // Le struct Campaign (Objet) contient les informations d'une campagne de crowdfunding
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    // Mapping qui permet d'associer un identifiant entier unique (uint256) à une campagne de crowdfunding
    mapping (uint256 => Campaign) public campaigns;

    // Nombre total de campagnes de crowdfunding créées (0 au départ)
    uint256 public numberOfCampaigns = 0;

    // Fonction qui permet de créer une campagne de crowdfunding
    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        // Check 1 : Vérification que chaque input doit être rempli pour valider l'envoi de la campagne
        require(bytes(_title).length > 0, "Title cannot be empty.");
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(_target > 0, "Target amount must be greater than 0.");
        require(_deadline > block.timestamp, 'The deadline must be a date in the future.');
        require(bytes(_image).length > 0, "Image URL cannot be empty.");
        
        // Check 2 : Vérification de doublons de campagnes
        uint256 campaignId = 0;
        bool isDuplicate = false;

        // Boucle do...while (economie de gas)
        // Vérification des doublons (avec keccak pour hashage des données)
        do {
        if (keccak256(bytes(campaigns[campaignId].title)) == keccak256(bytes(_title))) {
            isDuplicate = true;
            revert("Campaign with this title already exists.");
        }
        campaignId++;
    } while (campaignId < numberOfCampaigns);

    // Si pas de doublon :
    if(!isDuplicate){

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        campaignId = numberOfCampaigns;
        numberOfCampaigns++;
    }

        return numberOfCampaigns - 1;
    }

    // Fonction qui permet de faire un don à une campagne de crowdfunding
    function donateToCampaign(uint256 _id) public payable {
        require(msg.value > 0, "Donation amount must be greater than 0.");
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        // Envoi des fonds au créateur de la campagne
        (bool sent,) = payable(campaign.owner).call{value: amount}('');

        
        require(sent, "Failed to send funds");
            campaign.amountCollected = campaign.amountCollected + amount;
        
        
    }

    // Fonction getter qui retourne la liste des donateurs et des montants des dons pour une campagne donnée
    function getDonators(uint256 _id) view public returns(address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);

    }

    // Fonction getter qui retourne la liste de toutes les campagnes de crowdfunding
    function getCampaigns() public view returns(Campaign[] memory) {
        Campaign[] memory totalCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++){
            Campaign storage item = campaigns[i];

            totalCampaigns[i] = item;
        }

        return totalCampaigns;
    }
}

/*EXPLICATION DE CODE:
Ceci est un contrat intelligent écrit dans le langage de programmation Solidity pour une plateforme de financement participatif sur la blockchain Ethereum.

Il permet aux utilisateurs de créer des campagnes avec un titre, une description, un montant cible, une date limite et une image.
Il permet également aux utilisateurs de faire des dons aux campagnes en Ethers et fournit une fonction pour voir la liste de toutes les campagnes et leurs détails, ainsi que la liste des donateurs et les montants qu'ils ont donnés.

Le contrat utilise une structure de données en mapping pour stocker les campagnes, chaque campagne étant assignée à un identifiant unique (ID).
Le nombre de campagnes est stocké dans la variable "numberOfCampaigns".
*/