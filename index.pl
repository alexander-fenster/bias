#!/usr/bin/perl

use strict;
use warnings;
use HTML::Entities;
use JSON;
use List::Util qw(shuffle);

use lib '.';
use db;

use CGI::Pretty qw(:standard);

my $total = db::first_field("SELECT COUNT(1) FROM bias");
my $male = db::first_field("SELECT COUNT(1) FROM bias WHERE gender = 'm'");
my $female = db::first_field("SELECT COUNT(1) FROM bias WHERE gender = 'f'");
my @male = db::query_hashref("SELECT * FROM bias WHERE gender = 'm' ORDER BY rand() LIMIT 20");
my @female = db::query_hashref("SELECT * FROM bias WHERE gender = 'f' ORDER BY rand() LIMIT 20");
my @random = shuffle(@male, @female);
@random = @random[0 .. 9];

my $json = [];
foreach my $code (@random)
{
    my $source = encode_entities($code->{source});
    my $id = $code->{id};
    my $name = $code->{firstname};
    my $english_name = $code->{english_name};
    my $gender = $code->{gender};
    push @$json, {
        id => $id,
        name => $name,
        english_name => $english_name,
        source => $source,
        gender => $gender,
    };
}
my $jsondump = to_json($json);



print header(-type => 'text/html', -charset => 'utf-8');
print start_html(-title => "Unconscious bias");
print h1("Unconscious bias");

print <<EOD;
<div id="preface">

<p>
The idea of this test is to show you that it can be very difficult to find out if a piece of code is written by a male or a female programmer.
I had been teaching first year students in Novosibirsk (Russia) for a few years, and I have a database containing all their solutions to 
simple tasks, such as basic algorithms, searching, sorting, and graphs; most of them are written in C, some in C++.
That's a big amount of data that can be used for making funny things like this one.
</p>

<p>
Interested? Let's start then.
</p>

<p>
<a href="http://feldgendler.livejournal.com/155015.html">Here</a> is a link to the original discussion, in Russian; 
thanks to Alexey Feldgendler for hosting that discussion and inspiring me to make this test.
</p>

<h2>Rules</h2>

<p>
You will be given ten code fragments, some of them were written by female students, others by male students.
For most of them it was the first year of computer programming and the first year of learning C programming language.
</p>

<p>
These fragments are picked randomly from a database which has $total programs, $male of them written by male students and 
$female by female students, but each of the fragments shown to you can be written by either male or female student with an equal probability.
</p>

<p>
Try to guess who is the author of each fragment.
If you refresh the page new programs will be shown and the test will restart (you will lose your progress). 
</p>

<p><small>
Note: unfortunately, due to a series of database backup-restore operations, all non-ASCII characters in the code fragments were lost and are shown as question marks.
But that's good for our test as it makes the task even harder as sometimes you could guess the author by reading his or her comments in Russian.
</small></p>
</div>
<div id="start_button">
<button onclick=\"next()\">Start test</button>
</div>

<div id="final" style="display: none">
<span style="font-size: 24px"><b>Results</b></span><br/><br/>
Congratulations! You've got <b><span id="final_correct"></span> correct out of <span id="final_total"></span></b>.<br/><br/>
You can try to pass this test again if you refresh the page.
</div>

<div id="code" style="display: none">
Code fragment #<span id="number"></span>. Correct answers so far: <span id="correct_answers"></span> of <span id="total"></span>.
<hr/>
<div id='codediv' style="overflow-y: scroll; height: 300px; min-height: 300px">
<pre id="source">
</pre>
</div>
<small>Internal fragment ID: <span id="internal_id"></span></small>
</div>
<hr/>
<div style="min-height: 190px">
<div id="selection" style="display: none">
<span id="selm" onclick="selected('m')" style="font-size: 72px; cursor: pointer">♂</span>
<span style="font-size: 72px">&nbsp;&nbsp;&nbsp;&nbsp;</span>
<span id="self" onclick="selected('f')" style="font-size: 72px; cursor: pointer">♀</span>
</div>
<div id="answer" style="display: none;">
<span id="true" style="display: none; color: green">You are right!</span>
<span id="false" style="display: none; color: red">Wrong answer!</span><br/><br/>
Student's name: <span id="author"></span><br/><br/>
<button onclick="next()">Next page</button>
</div>
</div>

<script>
var counter = -1;
var correct = 0;
var codelist = $jsondump;
var total = codelist.length;

function next()
{
    if (counter + 1 == total)
    {
        document.getElementById('final_correct').innerHTML = correct;
        document.getElementById('final_total').innerHTML = total;
        document.getElementById('final').style.display = 'block';
        document.getElementById('answer').style.display = 'none';
        document.getElementById('true').style.display = 'none';
        document.getElementById('false').style.display = 'none';
        document.getElementById('code').style.display = 'none';
        document.getElementById('selection').style.display = 'none';
    }
    else
    {
        document.getElementById('preface').style.display = 'none';
        document.getElementById('start_button').style.display = 'none';
        document.getElementById('answer').style.display = 'none';
        document.getElementById('true').style.display = 'none';
        document.getElementById('false').style.display = 'none';
        document.getElementById('code').style.display = 'block';
        document.getElementById('selection').style.display = 'block';
        document.getElementById('selm').style.color = 'black';
        document.getElementById('self').style.color = 'black';
        ++counter;
        show(counter);
    }
}

function show(number)
{
    document.getElementById('number').innerHTML = number + 1;
    document.getElementById('correct_answers').innerHTML = correct;
    document.getElementById('total').innerHTML = total;
    document.getElementById('source').innerHTML = codelist[number]['source'];
    document.getElementById('internal_id').innerHTML = codelist[number]['id'];
    document.getElementById('codediv').scrollTop = 0;
    window.scrollTo(0, 0);
}

function selected(gender)
{
    if (gender === codelist[counter]['gender'])
    {
        ++correct;
        document.getElementById('correct_answers').innerHTML = correct;
        document.getElementById('true').style.display = 'inline';
   
        document.getElementById('selm').style.color = gender === 'm' ? 'green' : 'black';
        document.getElementById('self').style.color = gender === 'f' ? 'green' : 'black';
    }
    else
    {
        document.getElementById('false').style.display = 'inline';

        document.getElementById('selm').style.color = gender === 'm' ? 'red' : 'black';
        document.getElementById('self').style.color = gender === 'f' ? 'red' : 'black';
    }
    document.getElementById('author').innerHTML = codelist[counter]['english_name'] + " (" + codelist[counter]['name'] + ")";
    document.getElementById('answer').style.display = 'block';
    window.scrollTo(0, document.body.scrollHeight);
}

</script>

Alexander Fenster, fenster<span id="at"></span>fenster<span id="dot"></span>name, <a href="https://plus.google.com/+AlexanderFenster">https://plus.google.com/+AlexanderFenster</a>.

<script>
document.getElementById('at').innerHTML = '\@';
document.getElementById('dot').innerHTML = '.';
</script>
EOD

print end_html();

