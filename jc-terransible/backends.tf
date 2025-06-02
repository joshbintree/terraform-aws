terraform { 
  cloud { 
    
    organization = "jc-terransible" 

    workspaces { 
      name = "terransible" 
    } 
  } 
}