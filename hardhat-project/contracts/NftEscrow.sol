// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftEscrow {

    uint256 public constant MONTHS_TO_SECONDS_CONVERSION = 30*24*60*60; // keep in mind we are using an epoch of 30 days, not necessarily a month

    struct Listing {
        bool isActive;
        address seller;
        address buyer;
        address nftContractAddress;
        address tokenId;
        uint256 lockTimeInSeconds;
        uint256 unlockTime;
        uint256 months; // this could also be called epochs, cycles, payment period, etc
        uint256 initialAmount;
        uint256 price;
        uint256 monthlyPaymentAmount;
        uint256 amountPaid;
        bool hasBuyer;
        bool completed;
        bool paidOff;
    }

    Listing[] public listings;


    function time() public view returns (uint256){
        return block.timestamp;
    }

    // @dev called by seller
    // using months for now, but we can create more functionality in the future - allowing time periods and epochs in terms of weeks and days as well. 
    // seller must approve contract for nft before calling
    function createListing(
        address _nftContractAddress, 
        uint256 _tokenId, 
        uint256 _months, 
        uint256 _price, 
        uint256 _initialAmount) public {
        
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "you are not the owner of this nft");
        require(IERC721(_nftContractAddress).getApproved(_tokenId) == address(this), "this address has not been approved by seller");
        //require deposit amount < listing price??

        Listing memory listing = Listing({
            seller: msg.sender,
            nftContractAddress: _nftContractAddress,
            tokenId: _tokenId,
            months: _months,
            price: _price,
            initialAmount: _initialAmount
            // lockTimeInSeconds = months*30*24*60*60; // create a constant for this conversion 
            // unlockTime = block.timestamp + lockTimeInSeconds;
            // monthlyPaymentAmount = price/months; // fix rounding error - just + 1?
        });

        listings.push(listing);
        
     
    }


    // @dev called by buyer 
    function acceptPaymentPlan(uint256 _listingIndex) public payable { 

        // lmk if there are any gas optimization suggestions here on using memory vs storage. It may even be more efficient to have an instance from both storage and memory, only using the storage instance when updating variables rather than reading them 
        Listing storage listing = listings[_listingIndex];
        // should we require listing exits here to be safe? It should throw an error if the index is larger than length of listings array
        
        require(!listing.completed, "this listing is no longer available");
        require(listing.isActive, "this listing is currently inactive");
        require(!listing.hasBuyer, "There is already a buyer for this listing");
        require(msg.value >= listing.initialAmount, "Did not send enough for the deposit");

        /** below, and in createListing function, is there a way to declare the interface then call from it? rather than wrapping an address every time?
         * ex: nftContact = IERC721(listing.address)
         * then: nftContract.ownerOf(listing.tokenId)
         * 
         * is it like this?: IERC721 nftContact = IERC721(listing.address)
         */
        require(IERC721(listing.nftContractAddress).ownerOf(listing.tokenId) == listing.seller, "seller is no longer the owner of this nft");
        require(IERC721(listing.nftContractAddress).getApproved() == address(this), "this address has not been approved by seller");

        IERC721(listing.nftContractAddress).safeTransferFrom(listing.seller, address(this), listing.tokenId);
        require(IERC721(listing.nftContractAddress).ownerOf(listing.tokenId) == address(this), "could not transfer nft from owner");


        listing.amountPaid = msg.value;   
        listing.buyer = msg.sender;
        listing.hasBuyer = true;
    }


    //called from buyer
    function makePayment() public payable {
        //require listing active 
        // require listing not complete
        //if total price is paid off, change completed to true, and approve buyer for nft. we'll need to have a transfer button somewhere for the buyer to then transfer the nft
        // ^^any possible hacks here for changing completed to true and locking up the nft in the contract??
        // how to prevent overpaying 
        // if paid off, approve buyer to withdraw (should this approval be done in a separate function?) 
        // emit paid off event?
    }

    function sellerWithdrawPayments(uint256 _listingIndex) public {
        //require msg is seller of listing
        //need balance of seller to withdraw - array of balances to keep up. must be updated when a payment is made also
        //send entire balance to seller 
        //prevent reentrancy here with ordering of code/updating balance + putting a lock 
        // can put a check here to make sure the seller does not have withdrawals totalling more than the price. this may require an array of amounts withdrawn
    }

    function buyerWithdrawNft() public {
        // this function can also be called from the payment function if fully paid off, or coded within the payment function after a check for it being paid off

    }

    function sellerWithdrawNft(uint256 _listingIndex) public {
        // require not paid off
        // require time period passed OR payment missed

    }

    // @dev called by seller
    function cancelListing(uint256 _listingIndex) public {
        Listing storage listing = listings[_listingIndex];
         //require caller is seller of listing
        // require buyer has defaulted OR there is no buyer
        //send any balance associated with listing
        //send nft back to seller
        // deactive listing
    }

    //need function for keeping listing active after seller defaults, but clears out the buyer
   


// called by seller 
    function reActivateListing(uint256 _listingIndex) public {
        Listing storage listing = listings[_listingIndex];
        require(listing.seller == msg.sender);
        require(!listing.active);
        listing.active == true;
    } 


    function getDueDates() public {}

    function getNextDueDate() public {}

    function getNextPaymemtAmount() public {}

    function getTotalAmountOwed() public {}

    function paymentMissed() public {
        // emits payment missed event?
        // returns boolean of if a payment has been missed
        // would prefer thi function to be view so doesn't cost anything to call 
        // should this function update the variable to default or put in different function so this one can be gasless 
    }




}