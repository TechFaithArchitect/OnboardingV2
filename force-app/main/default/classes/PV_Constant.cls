/**
* @description       : Constant class for Classes
* @author            : Impaqtive DevTeam
* @group             :
* @last modified on  : 12-06-2023
* @last modified by  : Impaqtive DevTeam
* Modifications Log
* Ver   Date         Author            Modification
* 1.0                      Initial Version
**/
public with sharing class PV_Constant {
   public static final Map<String, Decimal> typeAmount = new Map<String, Decimal>{
                                        'Repair Commercial'         => 150,
                                        'Antenna credit'            =>  56,
                                        'ODU move'                  =>  50,
                                        'Reinstall (Upgrade)'       => 110,
                                        'Reinstall (Service Call)'  => 120,
                                        'Reinstall Commercial'      => 150,
                                        'Repair'                    =>  80,
                                         'Trip fees'                =>   1,
                                         'Equipment credit'			=>    0
                                        
   };
      public static final Map<String, String> typeCategory = new Map<String, String>{
                                        'Repair Commercial'         => 'Commercial Add-on',
                                        'Antenna credit'            =>  'Coverage',
                                        'ODU move'                  =>  'Equipment',
                                        'Reinstall (Upgrade)'       =>  'Quality',
                                        'Reinstall (Service Call)'  =>  'Quality',
                                        'Reinstall Commercial'      =>  'Quality',
                                        'Repair'                    =>  'Warranty',
                                        'Trip fees'                 => 	'Coverage',
                                         'Equipment credit'			=>    'Equipment'
                                        
   };
}