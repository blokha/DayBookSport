use Tk;
use Tk::PNG;
use utf8;
use DBI;
use GD::Graph::lines;
use List::Util qw( min max );
#use Forks::Super;
#use threads;
#use threads::shared;

my @Font_labels=['times','18','normal'];
my @Font_edits=['times','18','bold'];

my $dbh=DBI->connect("dbi:SQLite:dbname=sport",'','') or die print "FUCK \n$DBI::errstr\n";


my $Main=MainWindow->new;
$Main->title("Спортивный дневник");
$Main->geometry("1200x550");
#Левый главный фрейм для ввода данных
my $Frame_InData=$Main->Frame( -width=>'200', -height=>'400');
#Правый главный фрейм для вывода данных
my $Frame_OutData=$Main->Frame(-width=>'1000', -height=>'400');
my $Image=$Main->Photo(-file=>'img.png') if (-e 'img.png');
my $Label_Photo=$Frame_OutData->Label(-image=>$Image);
#Кнопки выбора для графика
my $Radio_frame=$Frame_OutData->Frame();
my @graph_bd_name=('-','-','-','-','-','-','-','-','-','-','-');
$graph_bd_name[0]='weight:weight:kg';
my $Radio_weight=$Radio_frame->Checkbutton(-text=>'Вес',-offvalue=>"-",-onvalue=>'weight:weight:kg',-variable=>\$graph_bd_name[0],-command=>\&graph_bd);
my $Radio_girth=$Radio_frame->Checkbutton(-text=>'Грудь',-offvalue=>"-",-onvalue=>'antropometria:girth:cm',-variable=>\$graph_bd_name[1],-command=>\&graph_bd);
my $Radio_biceps=$Radio_frame->Checkbutton(-text=>'Бицепс',-offvalue=>"-",-onvalue=>'antropometria:biceps:cm',-variable=>\$graph_bd_name[2],-command=>\&graph_bd);
my $Radio_pre_baptism=$Radio_frame->Checkbutton(-text=>'Предплечье',-offvalue=>"-",-onvalue=>'antropometria:pre_baptism:cm',-variable=>\$graph_bd_name[3],-command=>\&graph_bd);
my $Radio_waist=$Radio_frame->Checkbutton(-text=>'Талия',-offvalue=>"-",-onvalue=>'antropometria:waist:cm',-variable=>\$graph_bd_name[4],-command=>\&graph_bd);
my $Radio_buttocks=$Radio_frame->Checkbutton(-text=>'Ягодицы',-offvalue=>"-",-onvalue=>'antropometria:buttocks:cm',-variable=>\$graph_bd_name[5],-command=>\&graph_bd);
my $Radio_bero=$Radio_frame->Checkbutton(-text=>'Бедро',-offvalue=>"-",-onvalue=>'antropometria:bero:cm',-variable=>\$graph_bd_name[6],-command=>\&graph_bd);
my $Radio_tibia=$Radio_frame->Checkbutton(-text=>'Голень',-offvalue=>"-",-onvalue=>'antropometria:tibia:cm',-variable=>\$graph_bd_name[7],-command=>\&graph_bd);
my $Radio_pw_squats=$Radio_frame->Checkbutton(-text=>'Приседания',-offvalue=>"-",-onvalue=>'powerlifting:squats:kg',-variable=>\$graph_bd_name[8],-command=>\&graph_bd);
my $Radio_pw_benchpress=$Radio_frame->Checkbutton(-text=>'Жим лежа',-offvalue=>"-",-onvalue=>'powerlifting:benchpress:kg',-variable=>\$graph_bd_name[9],-command=>\&graph_bd);
my $Radio_pw_deadlift=$Radio_frame->Checkbutton(-text=>'Становая тяга',-offvalue=>"-",-onvalue=>'powerlifting:deadlift:kg',-variable=>\$graph_bd_name[10],-command=>\&graph_bd);
#Фрейм ввода веса
#извлечение последнего введеного значения веса для подстановки
my ($date1,$lastweight)=$dbh->selectrow_array("select  distinct date,weight from weight order by 1 desc limit 1");
my $Frame_Weight=$Frame_InData->Frame(-width=>'250',-height=>'50');
my $Label1=$Frame_Weight->Label(-text=>'ВЕС', -font=>@Font_labels);
my $Edit_Weight=$Frame_Weight->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastweight);
my $Label2=$Frame_Weight->Label(-text=>'кг', -font=>@Font_labels);
my $Label_weight_category=$Frame_Weight->Label(-text=>"Ваша весовая категория - ",-font=>@Font_labels);
my $ButtonWeight=$Frame_Weight->Button(-text=>'Записать',-font=>@Font_labels,-command=>sub{
	my $sth=$dbh->prepare("INSERT into weight (date,weight) VALUES(?,?)");
    my ($D, $M, $Y) = (localtime)[3,4,5];	$Y+=1900;	$M++; 
    if ($D<10){$D="0".$D}; if ($M<10){$M="0".$M};
    $sth->execute("$Y-$M-$D",$Edit_Weight->get());
    $Main->messageBox(-message=>"Запись прошла успешно",-type=>"ok")if defined($sth);
	
});
#Ввод данных для пауэрлифтинга
#~ my %power_normativ=(# {вес}{розряд}[пауэрлифтинг, жим, становая] WPA
	#~ "67.5"=>{"mc"=>[535.5 , 142.5, 202.5 ],"mcmk"=>[602.5, 160, 232.5]},
	#~ "75"=>{"mc"=>[577.5 , 155, 220],"mcmk"=>[650, 175, 255]},
	#~ "82.5"=>{"mc"=>[610 , 167.5, 235],"mcmk"=>[685, 187.5, 265]},
	#~ "90"=>{"mc"=>[635 ,175, 242.5 ],"mcmk"=>[715, 197.5, 272.5]},
	#~ );
my %power_normativ=(# {вес}{розряд}[пауэрлифтинг, жим, становая] WPA
	"67.5"=>{"mc"=>[ 477.50,125.00 , 175.00 ],"mcmk"=>[545.00, 145.00, 205.00]},
	"75"=>{"mc"=>[ 515.00,137.50 , 195.00 ],"mcmk"=>[587.50,157.50 ,222.50 ]},
	"82.5"=>{"mc"=>[ 542.50, 150.00, 202.50 ],"mcmk"=>[620.00, 172.50, 232.50]},
	"90"=>{"mc"=>[ 570.00, 157.50, 210.00 ],"mcmk"=>[647.50, 180.00, 240.00]},
	);
	
my $weight_kategory=0;
foreach (sort keys %power_normativ){
	$weight_kategory=$_;
	if ($_>$lastweight) {last;};
	}
$Label_weight_category->configure(-text=>"Ваша весовая категория - ".$weight_kategory." кг" );	
my $Frame_Powerlifting=$Frame_OutData->Frame(-borderwidth=>1,-relief=>"groove");
my $Label_squat=$Frame_Powerlifting->Label(-text=>"Приседания",-font=>@Font_labels);
($date1,$lastdata)=$dbh->selectrow_array("select distinct  date,squats from POWERLIFTING where squats>0 order by 1 desc limit 1");
my $Squart_edit=$Frame_Powerlifting->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
my $Button_squats=$Frame_Powerlifting->Button(-text=>"Записать",-command=> sub {
    my $sth=$dbh->prepare("INSERT into powerlifting (date,squats) VALUES(?,?)");
    my ($D, $M, $Y) = (localtime)[3,4,5];	$Y+=1900;	$M++; 
    if ($D<10){$D="0".$D}; if ($M<10){$M="0".$M};
    $sth->execute("$Y-$M-$D",$Squart_edit->get());
    $Main->messageBox(-message=>"Запись прошла успешно",-type=>"ok")if defined($sth);
	});

my $Label_benchpress=$Frame_Powerlifting->Label(-text=>"Жим лежа",-font=>@Font_labels);
($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,benchpress from POWERLIFTING where benchpress>0 order by 1 desc limit 1");
my $benchpress_edit=$Frame_Powerlifting->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
my $Label_benchpress1=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mc'}[1] кг",-font=>@Font_labels);
my $Label_benchpress2=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mcmk'}[1] кг",-font=>@Font_labels);
if ($lastdata<$power_normativ{$weight_kategory}{'mc'}[1]){
	$date1=$power_normativ{$weight_kategory}{'mc'}[1]-$lastdata;
	$Label_benchpress1->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mc'}[1] ($date1) кг"); }
elsif ($lastdata<$power_normativ{$weight_kategory}{'mcmk'}[1]){
	$date1=$power_normativ{$weight_kategory}{'mcmk'}[1]-$lastdata;
	$Label_benchpress2->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mcmk'}[1] ($date1) кг")};
my $Button_benchpress=$Frame_Powerlifting->Button(-text=>"Записать",-command=> sub {
    my $sth=$dbh->prepare("INSERT into powerlifting (date,benchpress) VALUES(?,?)");
    my ($D, $M, $Y) = (localtime)[3,4,5];	$Y+=1900;	$M++; 
        if ($D<10){$D="0".$D}; if ($M<10){$M="0".$M};

    $sth->execute("$Y-$M-$D",$benchpress_edit->get());
	 $Main->messageBox(-message=>"Запись прошла успешно",-type=>"ok")if defined($sth);
	});

my $Label_deadlift=$Frame_Powerlifting->Label(-text=>"Становая тяга",-font=>@Font_labels);
($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,deadlift from POWERLIFTING where deadlift>0 order by 1 desc limit 1");
my $deadlift_edit=$Frame_Powerlifting->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
my $Label_deadlift1=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mc'}[2] кг",-font=>@Font_labels);
my $Label_deadlift2=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mcmk'}[2] кг",-font=>@Font_labels);
if ($lastdata<$power_normativ{$weight_kategory}{'mc'}[2]){
	$date1=$power_normativ{$weight_kategory}{'mc'}[2]-$lastdata;
	$Label_deadlift1->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mc'}[2] ($date1) кг"); }
elsif ($lastdata<$power_normativ{$weight_kategory}{'mcmk'}[2]){
	$date1=$power_normativ{$weight_kategory}{'mcmk'}[2]-$lastdata;
	$Label_deadlift2->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mcmk'}[2] ($date1) кг")};
my $Button_deadlift=$Frame_Powerlifting->Button(-text=>"Записать",-command=> sub {
    my $sth=$dbh->prepare("INSERT into powerlifting (date,deadlift) VALUES(?,?)");
    my ($D, $M, $Y) = (localtime)[3,4,5];	$Y+=1900;	$M++; 
        if ($D<10){$D="0".$D}; if ($M<10){$M="0".$M};

    $sth->execute("$Y-$M-$D",$deadlift_edit->get());
	$Main->messageBox(-message=>"Запись прошла успешно",-type=>"ok")if defined($sth);
	});

my $sum=$Squart_edit->get()+$benchpress_edit->get()+$deadlift_edit->get();
my $Label_powerlifting_sum=$Frame_Powerlifting->Label(-text=>"Сумма",-font=>@Font_labels);
my $Label_powerlifting_sum1=$Frame_Powerlifting->Label(-text=>"$sum кг",-font=>@Font_labels);
my $Label_powerlifting_sum2=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mc'}[0] кг",-font=>@Font_labels);
my $Label_powerlifting_sum3=$Frame_Powerlifting->Label(-text=>"$power_normativ{$weight_kategory}{'mcmk'}[0] кг",-font=>@Font_labels);

if ($sum<$power_normativ{$weight_kategory}{'mc'}[0]){
	$date1=$power_normativ{$weight_kategory}{'mc'}[0]-$sum;
	$Label_powerlifting_sum2->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mc'}[0] ($date1) кг"); }
elsif ($sum<$power_normativ{$weight_kategory}{'mcmk'}[0]){
	$date1=$power_normativ{$weight_kategory}{'mcmk'}[0]-$sum;
	$Label_powerlifting_sum3->configure(-fg=>"red",-text=>"$power_normativ{$weight_kategory}{'mcmk'}[0] ($date1) кг")};

my $Label_info_power=$Frame_Powerlifting->Label(-text=>"Результаты",-font=>@Font_labels);
my $Label_info_power1=$Frame_Powerlifting->Label(-text=>"МС",-font=>@Font_labels);
my $Label_info_power2=$Frame_Powerlifting->Label(-text=>"МСМК",-font=>@Font_labels);
sub graph_bd {
my @graph_many=();
my @data1=();
my $title_all="";
my @legend=();
foreach(@graph_bd_name){
	if( $_ ne "-") {push (@graph_many,$_);}};
foreach (@graph_many){
my @db_radio=split/:/,$_;
$title_all=$title_all.'- '.$db_radio[1];
push (@legend,$db_radio[1]);
#my $dbh=DBI->connect("dbi:SQLite:dbname=sport",'','') or die print "FUCK \n$DBI::errstr\n";
$sql_string='select  distinct date,'.$db_radio[1].' from '.$db_radio[0].' where '.$db_radio[1].'>0 order by date desc limit 15';
my $sth=$dbh->prepare($sql_string);
$sth->execute(); 
my (@weight,@day)=();
while(my @row=$sth->fetchrow_array){
unshift(@weight,$row[1]);
unshift(@day,$row[0]);
};
if (@data1){push(@data1,\@weight);}
else {push(@data1,\@day,\@weight);};
};
my $linegraph=GD::Graph::lines->new(700,300);
$linegraph->set(
	x_label => 'Date',
	title =>$title_all ,
	x_labels_vertical=>1,
    long_ticks=>1,
    line_width=>2,
    y_tick_number=>5,
	) or die $linegraph->error;
$linegraph->set_legend(@legend);
my $lineimage=$linegraph->plot(\@data1);
#~ # convert into png data
open my $out, '>', 'img.png' or die;
binmode $out;
print $out $lineimage->png;
close $out;
my $Image=$Main->Photo(-file=>'img.png');
$Label_Photo->configure(-image=>$Image) if defined($Label_Photo);

#system 'img.png';	
	};

#Фрейм антропометрии
my %ideal=(
	"0.396"=>{"girth"=>"98.2",
	      "biceps"=>"35.2",
	      "pre_baptism"=>"29.5",
	      "waist"=>"73.5",
	      "buttocks"=>"88.2",
	      "bero"=>"53",
	      "tibia"=>"35.2",},
	"0.423"=>{"girth"=>"101.7",
	      "biceps"=>"36.5",
	      "pre_baptism"=>"30.5",
	      "waist"=>"75",
	      "buttocks"=>"91.5",
	      "bero"=>"55",
	      "tibia"=>"36.5",},
	"0.451"=>{"girth"=>"105.2",
	      "biceps"=>"37.7",
	      "pre_baptism"=>"31.5",
	      "waist"=>"79",
	      "buttocks"=>"94.70",
	      "bero"=>"56.7",
	      "tibia"=>"37.7",},
    "0.480"=>{"girth"=>"108.7",
	      "biceps"=>"39.2",
	      "pre_baptism"=>"32.7",
	      "waist"=>"81.5",
	      "buttocks"=>"98",
	      "bero"=>"58.7",
	      "tibia"=>"39.2"},
    "0.511"=>{"girth"=>"112.5",
	      "biceps"=>"40.5",
	      "pre_baptism"=>"33.7",
	      "waist"=>"84.2",
	      "buttocks"=>"101.2",
	      "bero"=>"60.7",
	      "tibia"=>"40.5"},
	"0.542"=>{"girth"=>"116",
	      "biceps"=>"41.7",
	      "pre_baptism"=>"34.7",
	      "waist"=>"87",
	      "buttocks"=>"104.2",
	      "bero"=>"62.5",
	      "tibia"=>"41.7"},
	"0.579"=>{"girth"=>"120",
	      "biceps"=>"43.2",
	      "pre_baptism"=>"36",
	      "waist"=>"90",
	      "buttocks"=>"108",
	      "bero"=>"64.7",
	      "tibia"=>"43.2"},
	"0.613"=>{"girth"=>"123.5",
	      "biceps"=>"44.5",
	      "pre_baptism"=>"37",
	      "waist"=>"92.7",
	      "buttocks"=>"111.2",
	      "bero"=>"66.7",
	      "tibia"=>"44.5"},
	);
	
my $w_h=0;
my $w_h_my=$lastweight/167; #167 см мой рост
my $mind=abs($w_h-$w_h_my);
foreach my $w_h_key (keys %ideal){
	if ($mind>abs($w_h_key-$w_h_my)){
		$mind=abs($w_h_key-$w_h_my);
		$w_h=$w_h_key;
	};
};
	
	
my $Frame_Antropometrii=$Frame_InData->Frame(-width=>'250',-height=>'250');
my $Label_ANT=$Frame_Antropometrii->Label(-text=>'Антропометрические данные',-font=>@Font_labels,-borderwidth=>2,-relief => 'groove');

my $Label3=$Frame_Antropometrii->Label(-text=>"Грудь",-font=>@Font_labels);
($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,girth from antropometria order by 1 desc limit 1");
my $Antrop_edit1=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
my $delta_ideal=$ideal{$w_h}{'girth'} -$lastdata;
my $Label4=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label4->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,biceps from antropometria order by 1 desc limit 1");
my $Label5=$Frame_Antropometrii->Label(-text=>"Бицепс",-font=>@Font_labels);
my $Antrop_edit2=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'biceps'} -$lastdata;
my $Label6=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label6->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,pre_baptism from antropometria order by 1 desc limit 1");
my $Label7=$Frame_Antropometrii->Label(-text=>"Предплечье",-font=>@Font_labels);
my $Antrop_edit3=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'pre_baptism'} -$lastdata;
my $Label8=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label8->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,waist from antropometria order by 1 desc limit 1");
my $Label9=$Frame_Antropometrii->Label(-text=>"Талия",-font=>@Font_labels);
my $Antrop_edit4=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'waist'} -$lastdata;
my $Label10=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label10->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,buttocks from antropometria order by 1 desc limit 1");
my $Label11=$Frame_Antropometrii->Label(-text=>"Ягодицы",-font=>@Font_labels);
my $Antrop_edit5=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'buttocks'} -$lastdata;
my $Label12=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label12->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,bero from antropometria order by 1 desc limit 1");
my $Label13=$Frame_Antropometrii->Label(-text=>"Бедро",-font=>@Font_labels);
my $Antrop_edit6=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'bero'} -$lastdata;
my $Label14=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label14->configure(-fg=>"red");};

($date1,$lastdata)=$dbh->selectrow_array("select  distinct date,tibia from antropometria order by 1 desc limit 1");
my $Label15=$Frame_Antropometrii->Label(-text=>"Голень",-font=>@Font_labels);
my $Antrop_edit7=$Frame_Antropometrii->Entry(-width=>'5',-font=>@Font_edits,-textvariable=>$lastdata);
$delta_ideal=$ideal{$w_h}{'tibia'} -$lastdata;
my $Label16=$Frame_Antropometrii->Label(-text=>sprintf("%.2f см",$delta_ideal),-font=>@Font_labels);
if ($delta_ideal>0){$Label16->configure(-fg=>"red");};

my $ButtonAntro=$Frame_Antropometrii->Button(-text=>'ЗАПИСАТЬ',-font=>@Font_labels,-command=>sub{
	my $sth=$dbh->prepare("INSERT into antropometria (date,girth,biceps,pre_baptism,waist,buttocks,bero,tibia) VALUES(?,?,?,?,?,?,?,?)");
    my ($D, $M, $Y) = (localtime)[3,4,5];	$Y+=1900;	$M++; 
        if ($D<10){$D="0".$D}; if ($M<10){$M="0".$M};
    $sth->execute("$Y-$M-$D",$Antrop_edit1->get(),$Antrop_edit2->get(),$Antrop_edit3->get(),
    $Antrop_edit4->get(),$Antrop_edit5->get(),$Antrop_edit6->get(),$Antrop_edit7->get());
     $Main->messageBox(-message=>"Запись прошла успешно",-type=>"ok")if defined($sth);
	 });

#Упаковка компонентов
$Frame_InData->pack(-side=>'left', -fill=>'both',-ipadx=>'5',-ipady=>'15');
$Frame_OutData->pack(-side=>'right', -fill=>'both');
#Компоновка выходных данных
$Label_Photo->grid(-row=>0,-column=>0, -sticky=>'nw');
$Radio_frame->grid(-row=>0,-column=>1,-sticky=>'ne');
$Frame_Powerlifting->grid(-row=>1,-column=>0,-sticky=>'w',-ipadx=>5,-ipady=>5, -pady=>"20");

$Radio_weight->pack(-side=>'top',-anchor=>'w');
$Radio_girth->pack(-side=>'top',-anchor=>'w');
$Radio_biceps->pack(-side=>'top',-anchor=>'w');
$Radio_pre_baptism->pack(-side=>'top',-anchor=>'w');
$Radio_waist->pack(-side=>'top',-anchor=>'w');
$Radio_buttocks->pack(-side=>'top',-anchor=>'w');
$Radio_bero->pack(-side=>'top',-anchor=>'w');
$Radio_tibia->pack(-side=>'top',-anchor=>'w');
$Radio_pw_squats->pack(-side=>'top',-anchor=>'w');
$Radio_pw_benchpress->pack(-side=>'top',-anchor=>'w');
$Radio_pw_deadlift->pack(-side=>'top',-anchor=>'w');

$Label_info_power->grid(-row=>0,-column=>1);
$Label_info_power1->grid(-row=>0,-column=>3);
$Label_info_power2->grid(-row=>0,-column=>4);

$Label_squat->grid(-row=>1,-column=>0,-sticky=>'w');
$Squart_edit->grid(-row=>1,-column=>1);
$Button_squats->grid(-row=>1,-column=>2);

$Label_benchpress->grid(-row=>2,-column=>0,-sticky=>'w');
$benchpress_edit->grid(-row=>2,-column=>1);
$Button_benchpress->grid(-row=>2,-column=>2);
$Label_benchpress1->grid(-row=>2,-column=>3,-padx=>"10");
$Label_benchpress2->grid(-row=>2,-column=>4,-padx=>"10");

$Label_deadlift->grid(-row=>3,-column=>0,-sticky=>'w');
$deadlift_edit->grid(-row=>3,-column=>1);
$Button_deadlift->grid(-row=>3,-column=>2);
$Label_deadlift1->grid(-row=>3,-column=>3);
$Label_deadlift2->grid(-row=>3,-column=>4);

$Label_powerlifting_sum->grid(-row=>4,-column=>0,-sticky=>'w');
$Label_powerlifting_sum1->grid(-row=>4,-column=>1);
$Label_powerlifting_sum2->grid(-row=>4,-column=>3);
$Label_powerlifting_sum3->grid(-row=>4,-column=>4);



#Компоновка фрейма ВЕСА
$Frame_Weight->pack(-side=>'top',-fill=>'y', -ipadx=>'5',-ipady=>'10');
$Label1->grid(-row=>'0',-column=>"0",-ipadx=>'1',-ipady=>'1');
$Edit_Weight->grid(-row=>'0',-column=>"1",-ipadx=>'5',-ipady=>'5');
$Label2->grid(-row=>'0',-column=>"2",-ipadx=>'1',-ipady=>'1');
$ButtonWeight->grid(-row=>'0',-column=>'3');
$Label_weight_category->grid(-row=>"1",-columnspan=>"4");

#компоновка фрейма Антропометрии
$Frame_Antropometrii->pack(-side=>'top',-fill=>'both', -ipadx=>'25',-ipady=>'25');
$Label_ANT->grid(-row=>0,-columnspan=>'3',-pady=>5,-ipadx=>5,-ipady=>5,-sticky =>'n');

#Грудь
$Label3->grid(-row=>1,-column=>0, -sticky=>'w');
$Antrop_edit1->grid(-row=>1,-column=>1,-pady=>'2');
$Label4->grid(-row=>1,-column=>2);
#Бицепс
$Label5->grid(-row=>2,-column=>0, -sticky=>'w');
$Antrop_edit2->grid(-row=>2,-column=>1,-pady=>'2');
$Label6->grid(-row=>2,-column=>2);
#предплечье
$Label7->grid(-row=>3,-column=>0, -sticky=>'w');
$Antrop_edit3->grid(-row=>3,-column=>1,-pady=>'2');
$Label8->grid(-row=>3,-column=>2);
#талия
$Label9->grid(-row=>4,-column=>0, -sticky=>'w');
$Antrop_edit4->grid(-row=>4,-column=>1,-pady=>'2');
$Label10->grid(-row=>4,-column=>2);
#ягодицы
$Label11->grid(-row=>5,-column=>0, -sticky=>'w');
$Antrop_edit5->grid(-row=>5,-column=>1,-pady=>'2');
$Label12->grid(-row=>5,-column=>2);
#бедро
$Label13->grid(-row=>6,-column=>0, -sticky=>'w');
$Antrop_edit6->grid(-row=>6,-column=>1,-pady=>'2');
$Label14->grid(-row=>6,-column=>2);
#голень
$Label15->grid(-row=>7,-column=>0, -sticky=>'w');
$Antrop_edit7->grid(-row=>7,-column=>1,-pady=>'2');
$Label16->grid(-row=>7,-column=>2);

$ButtonAntro->grid(-pady=>15,-row=>8,-columnspan=>'3',-sticky =>'n');

MainLoop;
__END__
Обновлять значения после записи

