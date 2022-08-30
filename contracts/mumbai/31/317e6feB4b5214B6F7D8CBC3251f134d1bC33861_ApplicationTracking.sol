// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.11;
import "./ApplicationTrackingLibrary.sol";
contract ApplicationTracking{
    
   
    mapping(bytes32 => ApplicationTrackingLibrary.UnitTissuePaper  ) public UnitTissuePapers;
    mapping(bytes32 => ApplicationTrackingLibrary.UnitJumboRoll  ) public UnitJumboRolls;
    mapping(bytes32 => ApplicationTrackingLibrary.UnitPulp  ) public UnitPulps;
    mapping(bytes32 => ApplicationTrackingLibrary.UnitForestry  ) public UnitForestries;
    
    
    event UnitTissuePaperCreated(bytes32 indexed  KeyId);
    event UnitJumboRollCreated(bytes32 indexed  KeyId);
    event UnitPulpCreated(bytes32 indexed  KeyId);
    event UnitForestryCreated(bytes32 indexed  KeyId);


    mapping(address=>bool) public Owners;
    address public Owner;

    modifier onlyOwner() {
        require(
            Owners[msg.sender]==true,
            "Only owner can call this function."
        );
        _;
    }

    constructor() {
        Owners[msg.sender]=true;
    }

     function isExistUnitTissuePaper(bytes32 Id)  public view returns(bool isIndeed) 
    {
       
        return (UnitTissuePapers[Id].Id == Id);
    }
    
    function AddUnitTissuePaper( ApplicationTrackingLibrary.UnitTissuePaper calldata uF ) external onlyOwner  {
      
         require(!isExistUnitTissuePaper(uF.Id),"Data Tissue Paper Already Exist !") ;

        UnitTissuePapers[uF.Id].Id=uF.Id;
        UnitTissuePapers[uF.Id].ProductTime=uF.ProductTime;
        UnitTissuePapers[uF.Id].PlantAddress=uF.PlantAddress;
      
                 
        emit  UnitTissuePaperCreated(uF.Id);
      

    }

    function isExistUnitJumboRoll(bytes32 Id)  public view returns(bool isIndeed) 
    {
       
        return (UnitJumboRolls[Id].Id == Id);
    }

    function AddUnitJumboRoll( ApplicationTrackingLibrary.UnitJumboRoll calldata uF ) external onlyOwner  {
      
         require(!isExistUnitJumboRoll(uF.Id),"Data JumboRoll Already Exist !") ;

        UnitJumboRolls[uF.Id].Id=uF.Id;
        UnitJumboRolls[uF.Id].ProductTime=uF.ProductTime;
        UnitJumboRolls[uF.Id].PlantAddress=uF.PlantAddress;
      
                 
        emit  UnitJumboRollCreated(uF.Id);
      

    }



    function isExistUnitPulp(bytes32 Id)  public view returns(bool isIndeed) 
    {
       
        return (UnitPulps[Id].Id == Id);
    }
      function AddUnitPulp( ApplicationTrackingLibrary.UnitPulp calldata uF ) external onlyOwner  {
      
         require(!isExistUnitPulp(uF.Id),"Data Pulp Already Exist !") ;

        UnitPulps[uF.Id].Id=uF.Id;
        UnitPulps[uF.Id].ProductTime=uF.ProductTime;
        UnitPulps[uF.Id].PlantAddress=uF.PlantAddress;
        UnitPulps[uF.Id].CertificateStatus=uF.CertificateStatus;
                 
        emit  UnitPulpCreated(uF.Id);
      

    }

    function isExistUnitForestry(bytes32 Id)  public view returns(bool isIndeed) 
    {
       
        return (UnitForestries[Id].Id == Id);
    }


     function AddUnitForestry( ApplicationTrackingLibrary.UnitForestry calldata uF ) external onlyOwner  {
      
         require(!isExistUnitForestry(uF.Id),"Data Forestry Already Exist !") ;

        UnitForestries[uF.Id].Id=uF.Id;
        UnitForestries[uF.Id].Company=uF.Company;
        UnitForestries[uF.Id].WoodSpecies=uF.WoodSpecies;
        UnitForestries[uF.Id].Certificate=uF.Certificate;
        
        UnitForestries[uF.Id].Distrik=uF.Distrik;
        UnitForestries[uF.Id].SiteAddress=uF.SiteAddress;
        UnitForestries[uF.Id].ReceivingRefference=uF.ReceivingRefference;
        UnitForestries[uF.Id].PlantCode=uF.PlantCode;
     
        emit  UnitForestryCreated(uF.Id);
      

    }





}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.11;
library ApplicationTrackingLibrary {

    struct UnitTissuePaper {
        
        bytes32    Id;  
        bytes32    ProductTime;
        bytes32 PlantAddress; 
          
       
    }

     struct UnitJumboRoll {
        bytes32    Id;  
        bytes32    ProductTime;
        bytes32 PlantAddress; 
       
    }

      struct UnitPulp {
        bytes32    Id; 
        bytes32    ProductTime;
        bytes32 PlantAddress; 
        bytes32 CertificateStatus; 
      
    }

      struct UnitForestry {
        bytes32    Id; 
        bytes32    Company;
        bytes32    WoodSpecies;
        bytes32    Certificate;
        bytes32 Distrik; 
        bytes32 SiteAddress; 
        bytes32 ReceivingRefference;
        string PlantCode; 
             

    }

   

    
}