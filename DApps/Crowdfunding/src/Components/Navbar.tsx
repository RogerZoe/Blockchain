'use client';
import Image from "next/image";
import Link from "next/link";
import { ConnectButton, lightTheme, useActiveAccount } from "thirdweb/react";
import { client } from "../app/client";
import thirdwebIcon from "@public/thirdweb.svg";

const Navbar = () => {
  const account = useActiveAccount();

  return (
    <nav className="bg-slate-100 border-b border-slate-300">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
        
        {/* Logo and Title */}
        <div className="flex items-center gap-2">
          <Image 
            src={thirdwebIcon}
            alt="Logo"
            width={32}
            height={32}
            style={{ filter: "drop-shadow(0px 0px 24px #a726a9a8)" }}
          />
          <span className="font-semibold text-slate-800 text-lg">My DApp</span>
        </div>

        {/* Navigation Links */}
        <div className="hidden sm:flex gap-4 items-center">
          <Link href="/">
            <p className="text-sm text-slate-700 hover:underline font-bold">Campaigns</p>
          </Link>
          {account && (
            <Link href={`/dashboard/${account.address}`}>
              <p className="text-sm text-slate-700 hover:underline">Dashboard</p>
            </Link>
          )}
        </div>

        {/* Connect Wallet Button */}
        <ConnectButton 
          client={client}
          theme={lightTheme()}
          detailsButton={{ style: { maxHeight: "40px" } }}
        />
      </div>
    </nav>
  );
};

export default Navbar;
