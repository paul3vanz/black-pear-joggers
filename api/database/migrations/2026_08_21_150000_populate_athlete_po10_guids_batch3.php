<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Third batch of Power of 10 GUIDs: the rows that landed in
 * tools/po10/review.csv rather than clearing verification automatically, gone
 * through by hand and accepted.
 *
 * These carry less evidence than the second batch, mostly an exact name plus
 * the profile listing our club, so they are kept in their own migration to be
 * rolled back on their own if one turns out wrong.
 *
 * Nine of the 312 reviewed rows are deliberately left out, because accepting
 * them would have been a guess rather than a decision:
 *
 *   Carlie Haynes, Rebecca Jones   two athlete records share the name and
 *                                  resolve to one profile, so the club has
 *                                  duplicate member records to merge first
 *   Robert Jones, Chris Berry      a second athlete record for someone already
 *                                  matched with stronger evidence
 *   James Moss                     profile already mapped to another athlete
 *   Joanne Walker, Kevin Kilmartin a second candidate scored equally
 */
return new class extends Migration
{
    // athlete_id => po10_guid  // name | evidence
    private array $map = [
        177331  => '882694e8-3ad0-4075-8700-57bb88494c77', // Denise Adams | club
        930077  => '375cff59-54ef-4b48-8b77-f6c2f9c91ed7', // Gina Addis | 1 same-day performance; club
        413786  => 'e0c40719-4e42-402a-a91e-7121c681f590', // Shelby Alexander | club
        154265  => 'cb77949d-3852-4b5f-8759-3dcf9ab0ddf4', // Ratan Alexander | club
        724392  => '38574a3b-ae45-4acb-bfae-20c88ad37a82', // Suzanne Allan | 1 same-day performance; club
        752117  => '694be0ce-7628-49c0-9478-7a171f56e346', // Ryan Allen | club
        353289  => '77e29156-7395-4f7e-aad3-99dd0d0f1b6e', // Wendy Allen | club
        282453  => '38a65709-f9fa-4a31-9c2e-c54f7a7578bc', // Beverley Allison | club
        861918  => '42ebde79-7dd3-4501-8448-ccce38ec8c66', // Emilie Andre | 1 same-day performance; club
        414031  => 'ba1ae8c2-a0ce-46b3-b604-3d4d7a700663', // Mark Arrowsmith | club
        631807  => 'e7c31941-1844-45cb-9d7d-fa074ceb964c', // Sue Ash | 1 same-day performance; club
        1210490 => '4b393091-c1f3-41b3-a46b-a9de179cde1c', // Mack Ashworth | club
        381275  => '371a47cf-1cce-446e-8827-06fe29d5888f', // Caroline Attwood-Reusser | club
        1137969 => '8af9bf69-1031-4e13-92a5-28f88e0869b6', // Katalin Babatunde-Kelen | club
        797332  => '828d6ed9-09e2-4ca0-9b1a-fef8e5c2ce39', // Christine Baigent-Reed | 1 same-day performance; club
        283918  => 'c407491f-a5df-457c-88d7-407a862535a0', // Joanne Bailey | club
        217174  => '2e41bcdc-8aa8-4eb1-aa43-495cf0542138', // David Bailey | 1 same-day performance; club
        605200  => 'd6986f8e-b1e3-4b1a-9c9e-f5dbcdb2171a', // Gareth Baker | club
        381622  => 'd2c27585-8643-4c66-a603-02bbd47619b2', // Ben Barnes | club
        414358  => '93228b50-b366-4242-aa3b-0147e6246da8', // Carly Barnes | 1 same-day performance; club
        1302971 => 'f530593e-af68-4a77-8d17-1020e110fec6', // Charlie Bassett | club
        285242  => 'af5b3524-4822-4268-9e51-084731f71ac8', // Mark Bates | club
        506062  => '1209ac08-cfc7-4f64-88e5-3f866da07aba', // Nick Bates | club
        1166264 => '023deb19-eb8e-42c7-99e2-852fdab43676', // Sam Beasley | 1 same-day performance; club
        798377  => '0997ec69-06f8-4240-8233-8438fecf10ca', // Kelvin Beeching | 1 same-day performance; club
        930551  => '8a660431-0677-4b88-843e-b165308626cb', // Maria Bell | 1 same-day performance; club
        286030  => '5b3889d2-1e17-46e0-a2cb-3df6d443715a', // Chris Bennett | club
        569810  => '3e48bd4d-1164-4cd7-b839-c56eafc70d1f', // Adrian Bennett | club
        774969  => '07234e14-ad4d-4007-bd9a-4c33ab574898', // Rachel Betteridge | club
        798985  => 'e544933d-b8c1-49ac-b0d1-782405f01d10', // Anne-Marie Bird | club
        1340283 => 'dc502bf1-103d-48d9-98b7-01a1a281b2e5', // Edward BLOCKLEY | club
        768370  => '80cef2cc-9d57-42b7-8deb-fcb9c82b2253', // Alison Bolton | club
        897051  => '2f32c5e5-75ee-4441-bf99-b140adc327b2', // Asa Booth | club
        530922  => 'b8859cf7-affb-4dec-83e4-3c6d93116e1b', // Michael Brazier | club
        863270  => '02c9f779-c695-4671-84e5-70fafd1e3585', // Victoria Briand | club
        970018  => 'd3594b42-9788-4ae2-af4a-1d42c34ce98c', // Roisin Brogan | 1 same-day performance; club
        1077728 => 'e1242e97-c51e-4047-b347-f9b2d24ba348', // Stuart Bromell | club
        939366  => 'af4d204f-fa9f-4414-a3fd-86b00ddf90e4', // Suzanne Bromley | club
        1224713 => '25e7fae3-e017-4fe8-875d-a00f19e87155', // Fred Brookes | club
        415408  => '8ad61348-b6cf-448f-a6c2-17c86ff7a6b1', // Rosie Brooks | club
        956095  => '62cab62d-d89c-4796-b292-da3a2fd7e181', // Alice Brooks | club
        897218  => '42e5366f-3177-4ce1-821e-8cf85b87aca6', // Rosie Brown | 1 same-day performance; club
        506942  => 'a4dcd971-23be-4913-97d6-e32c7f2ccb04', // Megan Burton | club
        1272577 => 'a5d9364a-2ac2-4ef1-9cc3-b907b674c754', // Christopher Caird | 1 same-day performance; club
        383836  => '06e30b84-db69-4357-bbe2-03efad3201f8', // Philippa Capel | club
        1275478 => '2b94af0d-8869-4120-a001-4884ed588465', // Usha Carter | club
        802744  => '489af70e-5d4a-40e2-a94f-3b0942175019', // Erin Cerrone | club
        160596  => 'b18716b4-cd3e-421f-97fd-44f4a8e67ef3', // William Chalmers | club
        985732  => '356f8a61-02e9-4a3f-810d-ef035ea327a3', // Kay Chesterman | club
        939569  => '0e3a1965-1b34-49bf-9e9f-09b17e21558e', // Roberto Ciancio | club
        668056  => 'd3566dbb-086c-4b40-922e-4c6d4a760751', // Emma Clarke | club
        292815  => 'aa8cf0c8-7484-4f40-bab6-78d36e22fabf', // Robert Clarke | club
        1047237 => '1ccfb890-3688-4058-866e-bbc59cc5a9c5', // Beth Clarke | club
        278942  => 'fc5f900c-28ac-422b-ad5b-73ab5c1b0e9d', // Nigel Cockrell | club
        699250  => 'f216e795-f286-4d89-a14b-0a57498683a2', // Carys Coleman | club
        1216169 => 'f65f7204-e53f-49f4-bee5-46da578e806e', // Ethan Collins | 1 same-day performance; club
        416661  => '131a0ce1-0ac0-4399-8a25-7c621d5a33bf', // Roger Cook | club
        1195377 => '4ae75c3f-cec5-40b2-9ac0-076a00dae4f2', // Lucy Corbett | club
        416812  => 'a36e8255-1dbb-488d-a38d-0aa8f8f1ade4', // Nick Cottrell | club
        294781  => '7a869006-216a-45b9-aca4-ee67d2f8bfb6', // Tim Coupe | club
        1013490 => '474712fe-2225-44a9-a625-10e64f7ff9fd', // Antoinette Cowling-Mahon | 1 same-day performance; club
        141337  => 'fdef4e04-91f3-4de1-b795-620ed7cb5bbb', // Adrian Cox | club
        1344855 => '9f0b4cb7-88f3-4387-8766-fba7d1314680', // Fiona Coy | club
        897815  => '0b4c9c32-24f8-4f43-9942-fcb8eb0538e3', // David Cutler | 1 same-day performance; club
        805525  => 'c1220457-f218-4558-a13a-a8c42f6e597a', // Amy  Darch | 1 same-day performance; club
        1207575 => '3084408d-0677-4bfb-b886-476da08c93d7', // Steve Dauncey-Smith | 1 same-day performance; club
        296563  => 'd7e97a20-f991-4de9-9a01-71d281da7043', // Robert Davidson | club
        771184  => '4911d6ba-d400-4305-b2ae-37af021cfa10', // Hugh Davies | club
        1235892 => 'd7c79b49-d992-4921-9109-e64c79de3114', // Abbie Davies | club
        1242260 => '9cfbaada-fcf8-4dc0-ba67-939e7278aa6a', // Rachel Dawes | 1 same-day performance; club
        1064093 => 'b3955bbf-1659-4da9-b6a0-b9c21548c734', // Jack Dennehy | 1 same-day performance; club
        978719  => 'ecafd5f2-ee34-4a71-8b2c-e2ca9b094302', // Natasha Dent | club
        986836  => 'bd28daa0-aeda-4fdd-9259-905e457cda3b', // David Dewett | club
        122507  => 'eb3ab1b5-703c-4aec-b7e2-b475042dff46', // Julie Dicker | club
        297779  => 'd30ebbc1-2634-4fa5-89aa-989b41145d89', // Tony Dicker | club
        915145  => '4a74663b-dfcf-4585-ad31-23ae536896cc', // Claire Diment | 1 same-day performance; club
        896239  => '8b850b81-5d30-458e-b576-e308e1ce3fa7', // Alan Dodson | 1 same-day performance; club
        971084  => '5be2933a-878e-4ece-86ea-94d19d74c2f8', // Antonio Doneddu | club
        1047603 => '79a5b596-96a5-43d2-b6ac-29fb899481f6', // Andrew Duddell | club
        450382  => 'b0a65b2c-b72e-4561-ac11-5687f07dcb46', // Rosanne Eardley | club
        299800  => '80fa997f-ee2c-4476-9f8b-7cde99716c8d', // Liz Edwards | club
        173156  => '32b169d1-972d-4427-b97e-4e1632c13eb5', // Rebecca Edwards | club
        987264  => 'b98914a9-4fda-403b-8845-03a82b80d044', // Debbie Edwards | 1 same-day performance; club
        1069584 => '94ab7807-55b1-456e-8d1c-37355c18edf4', // Steve Edwards | 1 same-day performance; club
        898151  => '7214ec26-00b4-4337-b34c-36716abbde08', // Claire Elliott | 1 same-day performance; club
        300539  => '2e241a28-1b89-42f9-be53-d749e4e231d0', // Amanda Eustace | club
        729605  => '10107317-71fb-41dd-9f81-55da9f687c03', // Rachel Evans | club
        701131  => '08bc802e-74fd-4034-bbe6-c77da5597b6c', // Vicky Evans | club
        898284  => '071253e1-c51a-4e11-85f4-6589d034f70f', // Laura Farwell | 1 same-day performance; club
        418314  => 'a9f5d448-f6aa-4854-b2e3-57a8c4a50d30', // Felicity Feek | club
        701321  => '1c9b72ce-ee0b-4665-89f6-cac42811567b', // Sarah Fernihough | club
        729823  => '776395fc-a67e-4f99-9439-e4868a5cd30b', // Faye Field | club
        1078175 => 'cf574ea2-1df3-43bf-ba41-7c5607e8a479', // Johanna Fleming | 1 same-day performance; club
        1238198 => 'be097dfc-f9c4-4748-9d6d-5ade94620435', // Albert Fones | 1 same-day performance; club
        670729  => '83cb5b01-da64-4914-9131-06820c1989c2', // Adrian Ford | club
        670731  => '48ed5b21-af76-4b93-adcd-2f26179b2258', // Barrie Ford | 1 same-day performance; club
        1244434 => 'a7085391-49c3-44ca-a1ee-4ce762312629', // Owen Fowler | club
        846694  => 'c52d5350-609b-4f78-9feb-39701c75c98a', // Beth Furniss | 1 same-day performance; club
        357467  => '751fd411-dffc-414c-8eaf-82d688a074a5', // Lorraine Gelder | club
        304378  => 'd530c0c2-6c94-4b77-bf34-91b7284fdb15', // Peter Gilbert | club
        611380  => '125b88b1-0d7e-4fe2-b57f-4d6425b7e1d3', // Louisa Gilchrist | club
        671290  => 'a78b9e5a-4198-44e1-953f-d30f60ad9388', // Rob Gillespie | club
        884499  => 'bf4bb120-a8ee-4cc4-be86-6d8f7a8375fc', // Rachel Gillgan | 1 same-day performance; club
        810703  => '062703b4-3ecf-4718-8e7d-8bb71fb55f1d', // David Gleave | club
        304803  => '1e736c9d-97fa-43ee-8837-94bfab207eb1', // Gemma Goddard | club
        278647  => '3489a27c-5efb-4a16-b461-d2a50323bebb', // James Goldby | club
        388449  => '1cd859d1-3fb7-4bfd-9f43-68be2e043dcf', // Clare Graham | club
        419191  => '6d57a3eb-cd1c-4ae7-a5fc-76b593cce576', // Jon Graves | club
        1029108 => '7d6c35ab-f251-43c9-992c-1bf762491fe2', // Laura Green | 1 same-day performance; club
        306020  => '8e89da29-e3d9-4772-8014-6888949a42d3', // Andrew Greenway | club
        89697   => '71a6f927-a035-49f1-8390-94df8b414a8a', // Lisa Gregory | club
        1147766 => 'c68ff83f-44b6-4ec2-8dcd-9c71dcfb1458', // Lucinda Griffiths | 1 same-day performance; club
        306483  => '8e2a5eee-7a94-4829-9235-25c15b7fa301', // Gay Grove | 1 same-day performance; club
        1256293 => '21e192b8-156b-410a-8e6c-e08adfaab5a2', // Kevin Grover | club
        1275785 => '7591113b-b4f1-47d5-ab21-05742230f48f', // Neil Haddon | club
        954819  => '99c2bb2b-554a-4007-9399-13f8900c087b', // Katy Hadfield | club
        358040  => '01ca2e63-679e-4211-b2e6-bed9c2b0c459', // Julie Hall | 1 same-day performance; club
        307467  => '13522dff-7110-4a42-978c-7d876e4dde5f', // Victoria Hancox | club
        731317  => 'c50f0a5e-1626-4abb-9e94-c2eb47c1f374', // Mat Hanlon | club
        510188  => '694a43e6-d748-4188-b711-7575905d8e6e', // Emma Harlow | club
        307967  => '0c35bf01-9838-4b24-bc33-45af4485bb99', // Lorraine Harris | club
        1275815 => '37e89d41-ef1a-4e7d-ad5c-5a8dca87a681', // Luke Harris | club
        999501  => '3bf425ab-a3db-4599-8033-a80e37780181', // Sally Harrison | 1 same-day performance; club
        1057305 => 'bd8d7af1-6cec-470b-bc9d-f7d78e29b615', // Sue Harrison-Ray | 1 same-day performance; club
        308351  => 'f55b48b4-382e-4fc8-9dcc-893fead3bf1d', // Michael Harte | club
        536567  => 'e6d38a33-f40f-41fb-82d8-22fb6edb1997', // Ross Henrys | club
        1303581 => 'fa673dbe-e5b4-40d4-9dfc-c0a1ac62ee0b', // Callum Hibbert | club
        522905  => 'cbca66ad-8c10-45f9-bd24-11df73eee4e6', // Theresa Higgins | club
        868622  => '36c777c3-0e15-4b94-bbce-da0793321440', // Sandra Hill | 1 same-day performance; club
        868619  => '09be2181-3a60-4947-8c66-f7436b345a36', // Rosemarie Hill | 1 same-day performance; club
        420323  => 'f6d19091-d071-409f-902c-3111a5055b02', // April Hodgkins | club
        673001  => '358c9df7-f582-422f-a5e0-22898880eeba', // Scott Holden | club
        138770  => 'db9b799c-ecba-4f0a-93e3-86aa277311e2', // Paul Holder | club
        630208  => '9b3c4d99-7316-464e-874c-d9ac26f9219f', // Sara Holloway | club
        732265  => 'b31d5b86-36b8-48f9-a077-dab2ea22288b', // Holly Holmes | club
        1255121 => '992afc97-9134-49e5-bd87-5cd9281b51b3', // Sian Holton-Webley | 1 same-day performance; club
        438534  => '0dd42873-07f7-498f-9482-7a6b2fcf4b9e', // Gareth Hooper | club
        311142  => 'ee933eff-0106-4507-999f-bd7de3a4efa2', // Jo Hooper | club
        1261862 => 'c80e97f2-6f06-4505-b821-56c283209aec', // Michael Hooper | 1 same-day performance; club
        390468  => '4761e720-d93e-4d12-902b-6cca99ceac30', // Amanda Hughes | club
        312325  => '45b2e254-f0e7-49d3-bd3f-6693162ff049', // Angela Hunt | club
        312344  => '13f45249-ee66-4795-a475-f41ccb99ead7', // Ian Hunt | club
        553930  => '2c5e3d4c-dd6f-4241-a7a7-e131a067df7a', // Adam Jackson | club
        452837  => '2355222b-aab3-40be-b4a3-0df34805c9da', // Penny James | club
        972883  => '89066c22-efef-4b78-b761-f74bcf40e92e', // Katie Jayne | 1 same-day performance; club
        899383  => '0dbf2959-4e68-4dde-9662-04bcbd1dec74', // Rebecca Jenkins | 1 same-day performance; club
        756610  => 'f041dedd-a94c-4dd1-90e1-f972a99c29e3', // Mary Jeynes | club
        1248118 => 'cc2e8cbc-dfc3-4048-982d-08ecba473023', // Ben Johnson | club
        278151  => '8e13dc66-fd7f-42e4-a53d-1b5435b8edec', // Anthony Jones | club
        816773  => 'b143c98f-2e14-47fa-af93-2672087ce09b', // Jon Jones | 1 same-day performance; club
        1275953 => 'e3c7a25a-5451-4db4-a735-701a2b324940', // Hannah Jones | club
        1357298 => '1d2da2ff-7ed6-4eb7-aac9-6f1d1e6183b7', // Ellie Jones | club
        1016678 => '24325583-0b5b-4f37-a821-fecd7b29974f', // Katy Jordan | 1 same-day performance; club
        149397  => 'c54b1f3c-3c3f-4515-99e7-4290aafb37f1', // Megan Judge | club
        453155  => 'a908c2cb-5270-4f71-b244-840f9b73f8ea', // Frauke Jung | club
        538106  => '90f90c09-aa8a-4e89-8ac6-7f8be7163ba9', // Ross Kane | club
        649351  => '7aad735e-59b6-41da-be45-77afffa577ba', // Sheila Keeble-Searle | club
        899587  => '91bb9639-80f5-498a-91b8-7554fcf4de2c', // Lesley Kennard | club
        277990  => '4ae35c2a-a7a2-4d9b-b1dc-ed7952a41558', // Robert Kennedy | club
        315682  => 'd8ec6680-ae96-4044-ab00-ca425714ecd9', // Adrian Kenney | club
        1017159 => '72cd18c4-d882-4b3c-9b97-208b8955a99a', // Wayne Kloos | 1 same-day performance; club
        1084633 => '4705a88e-1f94-43f6-8741-087f5b48c70a', // Ali Knight | 1 same-day performance; club
        316680  => '397f7064-f73f-444e-bcfe-c70539b54134', // Jasna Kos | club
        1272890 => 'f20b826e-dab5-42d4-9cc1-2f08d29067de', // Rachel Laing | 1 same-day performance; club
        392283  => '9aa5eb5d-25d4-4589-8f40-b663a0539266', // Jackie Larder | club
        1238544 => 'a35b7f2b-fe26-4818-8d69-ffa13021d8ae', // Cheeko Latino | club
        934317  => '34842864-7f8d-48bc-a6c9-0acd8ef7c920', // Sarah Lawrence | club
        1312390 => '29851860-d2fe-4d29-9300-8ec360f43a8d', // Sarah Layton | club
        1319328 => '38c45d84-8c79-4d3c-bbfc-d98098afd8aa', // Nicola Layton | club
        538934  => '9dde2135-2a54-4b3b-9f27-f6ed32dc4370', // Kimberley Leng | club
        538950  => 'bb2bb750-0a2a-45c9-9356-48f7ce8c949f', // Lucie Lessimore | club
        973467  => 'c8898513-a32c-4281-b25c-b7c46553f3fa', // Darren Leverett | club
        439258  => '28d03280-f2da-4b05-8c08-5e2b851124a1', // Gareth Lewis | club
        278032  => '6487fd68-2ec0-470d-a58f-90289c9426d3', // Victoria Lewis | club
        1218277 => '9246c443-6315-49b1-b6de-cd86c218f6f2', // Tilini Lilley | club
        392828  => 'b16af4f5-63a1-4214-8c6d-17f2664edf12', // Matthew Lloyd | club
        422435  => 'a7d396a7-b012-46f6-b86d-bb8ed911d3fe', // Shelley Lutz | club
        899905  => '9c5783b2-acb5-450c-ac56-64984dc2971a', // Ryan Lyttle | club
        422558  => '607f0f3f-70d7-4ed6-88d4-503bcb51a4ac', // Orla Mahanta | club
        945173  => 'bab00135-fe2c-4b48-b844-7d4e780b53ed', // Geraldine Mahon | 1 same-day performance; club
        1293875 => 'ba284bf1-475c-406d-b385-c14afc71b658', // Philip Marsh | 1 same-day performance; club
        1293881 => '4b0a37ce-5c42-4e5c-8b75-75e78ff65cdb', // Gareth Marshall | club
        1118347 => '33f06bdc-11e3-4e76-a899-bc5049c0cf00', // Andrew Martin | club
        321647  => 'e9555c5f-bc64-49a0-a4f4-f738700e0c21', // Robin Mayo | club
        991807  => 'a7883f98-3f43-4ecc-8d2c-63e7b0211ae7', // Nicky McDonald | 1 same-day performance; club
        411378  => '9088fcef-1e26-4bd3-8daa-4e009d62ac32', // Kevin McGettrick | 1 same-day performance; club
        322217  => '6d451742-e789-424d-bef1-fa72c2556a8c', // Paul McGinnes | 1 same-day performance; club
        851408  => '70a8e522-260c-4761-b9d9-a7d743f0b6f7', // Philip McGrahan | 1 same-day performance; club
        527453  => '0c81af89-3886-4235-97f4-433d52de6e32', // Neil Mcmillan | club
        439736  => '8a7cb407-a256-403b-aa54-bf718e2d6e8c', // Matt McNelis | club
        323453  => '2f04c489-236e-4d7e-9d25-24e5ee3a5a46', // Caroline Miles | club
        323682  => '691d43ce-45c5-40f3-8c1f-596842c2d98f', // Gill Mills | club
        765943  => '2a019f50-82bf-4512-839d-e50f8623be47', // Naomi Millward | club
        423433  => '4390c66a-89e9-49c5-81bc-6246879377d7', // Sally Mitchell | club
        324011  => '30569629-a7de-4afb-a7ee-b420eff048d2', // Cathy Mobley | 1 same-day performance; club
        136546  => '9050eee9-7e60-42a0-9815-76614fe1ee6b', // Elizabeth Moran | club
        922676  => '7879cec6-483b-490b-bd64-6828e39bfd2c', // Adam Moreton | 1 same-day performance; club
        941157  => '6edbc051-1773-4c3c-86eb-fbb5f3fee874', // Justine Morris | 1 same-day performance; club
        1261215 => 'ec41c127-8cf5-43c6-990a-f162559e65d5', // Lindsay Mottram | 1 same-day performance; club
        444481  => '63b97b43-a1cb-4320-ae80-db7cc56b9a73', // Vicki Moulston | club
        1103051 => 'd2f4cf26-9a88-4d56-beee-504036983c23', // Eoin Murphy | club
        325986  => '16436fcc-41c8-44d4-9246-d3b9e568011e', // Martin Nelson | club
        9909    => '24f53e34-8a40-47fd-a5fe-463c1403baab', // Alyson Noake | club
        395346  => '7c25d0b0-05d9-4e25-b5df-7cc1e0da7fbd', // Abby Oates | club
        395350  => '510692c8-32be-433e-a845-abb550eef6e4', // Steve Oates | club
        923242  => '1528fe8e-e46f-4fb1-bdbd-7526d2335665', // Steve Overall | club
        328239  => '07a49940-b7ed-45a5-93a7-39dd9f1ec45b', // Bharat Panchal | club
        636637  => 'c7080cfe-0c38-4fd8-be1a-5eea22c00a0e', // Natalie Parrott | club
        617976  => 'ded5aa11-7ae2-4620-b8d4-284e4c5731a2', // Kay Parry | club
        328779  => '9eabb5ec-ca90-4ddc-aa05-b95cb50e52b8', // Gavin Paskin | club
        951812  => '03cae6f4-8442-4f92-a389-d6e9ee914f1a', // Shaun Paskin | 1 same-day performance; club
        951830  => 'b68a4cb0-a4e3-44cd-892b-048e5631156e', // Mike Pattinson | club
        424642  => '1a8c17ca-cdcc-48e1-aeac-f66614bee2a5', // Madeleine Paul | club
        1233851 => 'd4884d7d-9d7f-4dd3-a369-7e08a777d850', // Rob Perks | club
        1346329 => '1356c731-ed43-48e3-8c95-d3ff9cb02682', // Sarah Peterson-Hill | club
        974876  => '9d1f28d9-f6de-48aa-af6f-9d6708ce1311', // anna phillips | club
        708568  => '1f642f76-8c61-4633-8744-101cfc06a024', // Emma Pickering | club
        330292  => '6afdbc3d-66ab-438b-9c2d-2045d7e0fa82', // Amanda Piper | club
        1186014 => 'd3327411-0ed4-4cd1-8a31-140fefcfc508', // Sam Plant | club
        514276  => '5b9f40b2-5564-4e73-bf7b-737b08bdf5ad', // Leon Plews | club
        1103250 => 'd3df66f4-290d-4776-ab8e-5ad607ff452f', // Donna Powell | club
        1264795 => 'a5eee9db-991d-420a-97dd-74e68c021e8a', // Saira Powell | club
        514421  => 'e9d836b3-f08f-4c6e-ae84-b55df692065d', // Sophie Price | club
        1294901 => 'bf8346b1-fcf7-43b2-894d-a969ae9d459b', // Paul Price | club
        993826  => '88b5905a-3daa-4876-b952-4cb057e71f54', // Gaynor Pritchard | 1 same-day performance; club
        741951  => '454d0d7a-09d9-4566-aa1d-a3d96df67ebe', // Trevor Pritchard | club
        847246  => 'f77a4dd8-bb7e-4969-aa74-fbfd70a8632e', // Kaine Pritchett | club
        331704  => 'a0d82524-a6dc-4c18-ae3c-6ce7b107ddbd', // Yvette Pygott | club
        331742  => '8f6b330b-b5b1-476e-bd13-358929074774', // David Quarterman | club
        227906  => '3adc4b4d-6ace-43b4-80bb-ade61dc635e0', // Mark Ralfe | club
        1346437 => '9c018364-1096-43fa-8dfa-7cec775b199a', // Jordan Rawlings | club
        709195  => '7ee99510-fba5-453f-a318-d0fab5cbd79e', // Anwen Rees | club
        742503  => 'b099842c-7207-4141-ba52-8722019accfd', // Heather Rimmer | club
        180299  => '5a85ef1a-e56d-438f-80f6-475b09ef481c', // Neil Robbie | club
        333686  => '8b483d04-a1fa-4a86-b676-0f98e4565ebc', // Bethan Roberts | club
        994487  => '466b98d2-f6ec-43b1-9a12-036675115d91', // jennie roberts | 1 same-day performance; club
        1309117 => '993fe824-9f1c-4091-ac2a-6393c60ddc13', // Dominic Roberts | club
        333930  => 'e2ff4856-7f0c-40c7-a17a-c1cdccd8d8bd', // Alan Robins | club
        844509  => 'f4ed1b86-193d-46c0-907a-3ad9d6ff3711', // James Robinson | club
        829176  => '80bf598d-fd48-4901-964d-c2cd3ba36d3a', // Alexandra Russell | 1 same-day performance; club
        936346  => '0840a6e7-ae44-4acf-bf88-8d0ab47c9804', // Natalie Russell | club
        1234296 => '996b0e32-fcc8-4eb9-9e27-4cd14f3c5517', // Patricia Scarle | club
        398226  => '8e898386-6456-4411-8ab6-9c39606a6de6', // Heather Scripps | club
        651687  => '071addae-fe46-4416-a4ae-58c381f54497', // Peter Searle | club
        411477  => 'a17d704f-5045-482c-bd9e-320e422968ea', // Ruth Semper | club
        620136  => 'a70e1f02-13f2-4845-9f03-068f27a8e6eb', // Paul Shaw | club
        146151  => 'c9671689-c7c5-47dc-bc0f-67407c67b59a', // Richard Sheldon | club
        952389  => 'b160e7d7-39e5-426c-92d8-08f564867a73', // Shehan Sinnathamby | 1 same-day performance; club
        1234435 => 'fcc8d8d5-2c7b-4587-b682-7f8823fb1d07', // Mark Smedley | club
        145960  => 'f972362a-0105-4a5e-82e2-0b5ec9d82753', // Gary Smith | club
        760200  => 'dfaf2033-9cf4-4400-8f65-96876d30aa13', // James Smith | club
        1300917 => 'f8b4386c-d2f5-497c-bd94-f51b289559fe', // Andrew Smith | club
        278654  => '3adb0396-5c90-47cb-a54e-5fcc143c944c', // Tom Smith | club
        364000  => '377a1077-f838-40ea-b132-c6e8961572b9', // Andrew Stafford | club
        996218  => '2b0f52a4-3ff6-4e4c-8ebf-942cbb12a30a', // Emma Stamper | 1 same-day performance; club
        427114  => '706a9da7-b2e8-49fe-83e6-9b96170f997d', // Andrew Starkey | club
        652104  => 'fecc32af-bfb8-437c-a606-7c2e01b9d897', // Carol Starkey | club
        711374  => '79e7e886-2c96-479c-ab0f-1f9926f9583b', // Maria Stead | club
        338774  => 'd6c1b0c1-576e-42e5-bce3-4192b30a0ff3', // Catherine Steele | club
        889535  => 'e88baefd-0f12-4d3b-ab3d-76d2a893df14', // David Stelling | 1 same-day performance; club
        544874  => '12b38475-246f-4e42-bcc7-f4bd59d1f5cb', // Andrew Stenson | 1 same-day performance; club
        544875  => '6ea8a3d3-5842-41bb-89b3-532793a1e309', // Ian Stenson | club
        338953  => '462e0dd1-018e-4279-bdad-d8448f60bb4a', // John Sterry | club
        338954  => 'd2b6e362-4fe8-4df4-ad0f-40436d339191', // Lesley Sterry | club
        735796  => '8e1db1fc-e05f-4d6c-8f58-b339b68faea9', // Greg Stocks | club
        1264360 => '0294db41-8cb7-4782-9d4f-163f8da93cc0', // Rachel Stone | 1 same-day performance; club
        1355886 => 'b8c288ed-a38d-418f-98b5-b54b3ab15ba8', // Lisa Sutton | club
        340080  => '9c4e8215-5088-449f-9eda-87f6e9c75b03', // Neal Sweeney | club
        340272  => 'd2c8015d-7e27-44e3-bba1-b08bcf914d26', // Leonardo Taggio | 1 same-day performance; club
        711927  => '14220497-0ac9-475b-aabb-acaea397af6f', // Hannah Talbot | club
        711930  => '3d360fd6-e034-4b44-8297-68740b905a6d', // Sally Talbot | club
        736338  => 'a1e1737f-23f9-4240-bf17-8c14ab96b2a4', // Sue Tarran | 1 same-day performance; club
        340555  => 'ccdf1441-b7fd-48c9-8733-5da4bd8d8e02', // Clare Taylor | club
        1305681 => '0cfa98b1-850e-473e-b172-2ee4b3180aa5', // Lucy Taylor | club
        901947  => '9dd2dad1-5366-4195-803a-f1f54ee99ea4', // Mark Thomas | club
        126031  => 'adf37508-89e8-423f-802f-b5b943d1dfab', // Kes Thornley | club
        681492  => 'ab46ea86-d512-4c01-b1ff-263ea1a0e26e', // Andrea Till | club
        554043  => '18d5a887-74cb-4395-863a-4c71b2d7ca5a', // Chris Tipton | club
        1360530 => 'bae08b5e-cbad-4ee9-bdb6-667614086a4b', // James Tombs | club
        681564  => 'c6aa6c41-10a2-47be-bb59-6eb689a0b6ee', // Michael Tomkinson | club
        621911  => 'a26f008a-534f-4d7d-8edc-94c016c452e7', // Kim Townsend | club
        1360545 => 'b038299b-0e8e-4c11-949e-a62625388484', // Lisa Trunks | club
        400574  => '8a04b315-49d4-4fd3-a60b-422fabae5879', // April Turner | club
        342875  => '375b2911-b32a-456a-9e41-947000eca68e', // Lance Turner | club
        1273219 => '5386f185-52d2-46f1-a442-4eb00c9c54ed', // Katie Vass | club
        1003640 => '3cdff26a-060f-493a-bbae-c9c3c7f2e941', // Shelley Waldie | 1 same-day performance; club
        344169  => 'fbfba248-0431-46d4-93b6-ea4090397b0e', // Mike Wall | club
        1169151 => '9a274c3f-20af-4863-8cbe-46d1ba5462e2', // Ian Wareing | club
        1004194 => '13a4f4db-621e-41f4-888b-89f1244d21b3', // Kay Webster | 1 same-day performance; club
        1227614 => '1e33f58f-c20f-46b4-8d35-6dd7d7b0b87f', // Adam Went | club
        845811  => '389ba8ff-e09f-4f98-bee3-3480c5f24b5f', // Sarah Wherry | club
        1021894 => 'b55f354f-db36-4479-8421-da5110159a25', // Claire Wilkin-Mead | 1 same-day performance; club
        623092  => 'b7b327e6-6513-4da8-b463-85fe4e70e1a1', // Rebecca Wilkins | club
        347037  => '3d667058-e887-4db2-8392-7e23c5560c50', // Grant Williams | club
        623206  => 'bb0e446a-05c2-4fcf-9fc4-4d752e3d3b5d', // Laura Williams | club
        937896  => '691ba099-3bf7-4868-9ffd-773c99df5d5a', // Gwyn Williams | club
        459343  => 'd0d3a70f-14f3-4893-9adb-267d8153bec5', // Stephen Wilson | club
        348026  => '56e55e2b-dea6-491c-a259-c6cbc66fa778', // Noel Wonfor | club
        1219186 => '8bd87e64-31a5-4aed-bcba-5fb7371d8775', // Beccy Woodward | 1 same-day performance; club
        547615  => '8f1f643c-c807-4388-8e16-52ae08638e6d', // Ross Wright | club
        744084  => 'c9402483-4056-4c72-bb49-620210b556e5', // Sally Wright | club
        902674  => '9b1cb8bc-349d-4740-8bdd-65aa54bf6d10', // Jo Yeomans | 1 same-day performance; club
        853961  => '3de4f665-4960-4516-bfe9-113d313125da', // Holly Yuille | 1 same-day performance; club
    ];

    public function up(): void
    {
        if (!Schema::hasColumn('athletes', 'po10_guid')) {
            return;
        }

        foreach ($this->map as $athleteId => $guid) {
            $takenBy = DB::table('athletes')
                ->where('po10_guid', $guid)
                ->where('athlete_id', '!=', $athleteId)
                ->value('athlete_id');

            if ($takenBy) {
                continue;
            }

            DB::table('athletes')
                ->where('athlete_id', $athleteId)
                ->whereNull('po10_guid')
                ->update(['po10_guid' => $guid]);
        }
    }

    public function down(): void
    {
        if (!Schema::hasColumn('athletes', 'po10_guid')) {
            return;
        }

        foreach ($this->map as $athleteId => $guid) {
            DB::table('athletes')
                ->where('athlete_id', $athleteId)
                ->where('po10_guid', $guid)
                ->update(['po10_guid' => null]);
        }
    }
};
