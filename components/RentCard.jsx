import React, { useContext, useState, useEffect } from "react";
import Link from "next/link";
import { NFTContext } from "../context/NFTContext";
import {
  useConnectionStatus,
  useDisconnect,
  useAddress,
} from "@thirdweb-dev/react"; 

const RentCard = ({ nft, onProfilePage }) => {
  const { nftCurrency, userOf } = useContext(NFTContext);
  const ownerAddress = nft.owner.toLowerCase();
  const currentAccountAddress = useAddress();
  const [days, setDays] = useState(0);
  const [hours, setHours] = useState(0);
  const [minutes, setMinutes] = useState(0);
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const targetDate = new Date(nft.expires);
    const interval = setInterval(() => {
      const now = new Date();
      const difference = targetDate - now;

      if (difference > 0) {
        setDays(Math.floor(difference / (1000 * 60 * 60 * 24)));
        setHours(Math.floor((difference / (1000 * 60 * 60)) % 24));
        setMinutes(Math.floor((difference / 1000 / 60) % 60));
        setSeconds(Math.floor((difference / 1000) % 60));
      } else {
        clearInterval(interval);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [nft.expires]);

  return (
    <div className="flex flex-col rounded-3xl border-solid hover:border-dotted m-3" style={{ backgroundColor: '#011627 ' }}>
      <div className="px-4 py-7 sm:p-10 sm:pb-6">
        <div className="grid items-center justify-center w-full grid-cols-1 text-left">
          <div>
            <h2 className="text-lg font-medium tracking-tighter text-white lg:text-3xl">
              {nft.name}
            </h2>
            <p className="mt-6 text-sm text-gray-100">ID: {nft.id}</p>
          </div>
          {(ownerAddress === currentAccountAddress && !nft.rented) ? (
              <>Your Asset is rented by somebody</>
          ): (userOf(nft.tokenId) === currentAccountAddress && nft.rented) ? (
            <div className="flex gap-5 mt-4 text-center">
              <div className="flex flex-col">
                <span className="countdown font-mono text-4xl">
                  <span style={{ "--value": `${days}` }}>{days}</span>
                </span>
                days
              </div>
              <div className="flex flex-col">
                <span className="countdown font-mono text-4xl">
                  <span style={{ "--value": `${hours}` }}>{hours}</span>
                </span>
                hours
              </div>
              <div className="flex flex-col">
                <span className="countdown font-mono text-4xl">
                  <span style={{ "--value": `${minutes}` }}>{minutes}</span>
                </span>
                min
              </div>
              <div className="flex flex-col">
                <span className="countdown font-mono text-4xl">
                  <span style={{ "--value": `${seconds}` }}>{seconds}</span>
                </span>
                sec
              </div>
            </div>
          ) : nft.rented ? (
              <>
                This NFT is already rented.
              </>
          ) : (
              <>
                {nft.forRent ? (
                <div className="mt-6">
                  <p>
                    <span className="text-5xl font-light tracking-tight text-white">
                      {nft.rentPrice}
                    </span>
                    <span className="text-base font-medium text-white"> {nftCurrency(nft)} /day </span>
                  </p>
                </div>
              ) : (
                <div className="mt-6">
                  <p>
                    <span className="text-5xl font-light tracking-tight text-white">
                      {nft.price}
                    </span>
                    <span className="text-base font-medium text-white"> {nftCurrency(nft)}</span>
                  </p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
      <Link href={{ pathname: '/nft-details', query: nft }}>
        <div className="flex px-6 pb-8 sm:px-8">
          <a aria-describedby="tier-starter" className="items-center justify-center w-full px-6 py-2.5 text-center text-black duration-200 bg-white border-2 border-white rounded-full inline-flex hover:bg-transparent hover:border-white hover:text-white focus:outline-none focus-visible:outline-white text-sm focus-visible:ring-white" href="#">
            View More
          </a>
        </div>
      </Link>
    </div>
  )
};

export default RentCard;
