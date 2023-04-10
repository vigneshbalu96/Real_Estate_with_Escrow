//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public lender;

    mapping (uint256 => bool) public isListed;
    mapping (uint256 => uint256) public purchasePrice;
    mapping (uint256 => uint256) public escrowAmount;
    mapping (uint256 => address) public buyer;
    mapping (uint256 => bool) public inspectionPassed;
    mapping (uint256 => mapping(address => bool)) public approval;

    modifier onlySeller(){
        require (msg.sender == seller, "only seller can call the method");
        _;
    }
    modifier onlyBuyer(uint256 _nftId){
        require (msg.sender == buyer[_nftId], "only buyer can call the method");
        _;
    }
    modifier onlyInspector(){
        require (msg.sender == inspector, "only inspector can call the method");
        _;
    }
    constructor (address _nftAddress, address payable _seller, address _inspector, address _lender){
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    function list (uint256 _nftID, address _buyer, uint256 _purchasePrice, uint256 _escrowAmount) public payable onlySeller {
        //Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);
        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    function updateInspectionStatus(uint256 _nftID, bool _passed) public onlyInspector {
        inspectionPassed[_nftID] = _passed;
    }

    //Depositing the Earnest(onlyBuyer & payable escrow)
    function depositEarnest(uint256 _nftID) public payable onlyBuyer (_nftID) {
        require(msg.value >= escrowAmount[_nftID]);
    }

    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    // Finalize Sale
    // Require Inspection Status
    // Require sale to be authorized
    // Require funds to be correct amount
    // Transfer NFT to the buyer
    // Transfer funds to the seller

    function finalizeSale (uint256 _nftID) public {
        require (inspectionPassed[_nftID]);
        require (approval[_nftID][buyer[_nftID]]);
        require (approval[_nftID][seller]);
        require (approval[_nftID][lender]);
        require (address(this).balance >= purchasePrice[_nftID]);

        (bool success, ) = payable (seller).call {value : address(this).balance} (" ");
        require (success, 'Did not work out');

        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    receive () external payable {}
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
}
