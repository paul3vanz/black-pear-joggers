<!doctype html>
<html lang="en">
<head>
    <title>Record Magic Mile</title>
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO" crossorigin="anonymous">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js" integrity="sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js" integrity="sha384-ChfqqxuZUCnJSK3+MXmPNIyE6ZbWh2IMqE241rYiqJxyMiZ6OW/JmZQ5stwEULTy" crossorigin="anonymous"></script>
</head>
<body>
    <div class="container">
        <div class="row">
            <div class="col">
                <h1 class="mb-4">Record Magic Mile</h1>
            </div>
        </div>
        <div class="row">
            <div class="col">
                <div id="save-success" class="alert alert-success d-none" role="alert">
                    Result saved successfully.
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col">
                <div id="save-error" class="alert alert-danger d-none" role="alert">
                    <p>There was an error saving the result:</p>
                    <div id="error-messages"></div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-12">
                <form>
                    <div class="form-group row"><label class="col-3" for="date">Date</label>
                        <input type="text" name="date" id="date" placeholder="e.g. 2018-07-28" class="form-control col">
                    </div>

                    <div class="form-group row"><label class="col-3" for="location">Location</label>
                        <select name="location" id="location" class="form-control col">
                            <option value="Magic Mile (Diglis Bridge)">Diglis Bridge</option>
                            <option value="Magic Mile (Grandstand)">Grandstand</option>
                        </select>
                    </div>

                    <div class="form-group row"><label class="col-3" for="first_name">First name</label>
                        <input type="text" name="first_name" id="first_name" class="form-control col" autocomplete="no">
                    </div>

                    <div class="form-group row"><label class="col-3" for="last_name">Last name</label>
                        <input type="text" name="last_name" id="last_name" class="form-control col" autocomplete="no">
                    </div>

                    <div class="row">
                        <div id="athlete-search-results" class="col offset-3"></div>
                    </div>

                    <div class="form-group row"><label class="col-3" for="gender">Gender</label>
                        <select name="gender" id="gender" class="form-control col">
                            <option value="M">Male</option>

                            <option value="W">Female</option>
                        </select>
                    </div>

                    <div class="form-group row"><label class="col-3" for="category">Category</label>
                        <select name="category" id="category" class="form-control col">
                            <option value="U20">Under 20</option>
                            <option value="U23">Under 23</option>
                            <option value="SEN" selected>Senior (23-34)</option>
                            <option value="V35">V35-39</option>
                            <option value="V40">V40-44</option>
                            <option value="V45">V45-49</option>
                            <option value="V50">V50-54</option>
                            <option value="V55">V55-59</option>
                            <option value="V60">V60-64</option>
                            <option value="V65">V65-69</option>
                            <option value="V70">V70+</option>
                        </select>
                    </div>

                    <div class="form-group row"><label class="col-3" for="predicted_time">Predicted time</label>
                        <select name="predicted_time" id="predicted_time" class="form-control col">
                            <option>03:00</option><option>03:01</option><option>03:02</option><option>03:03</option><option>03:04</option><option>03:05</option><option>03:06</option><option>03:07</option><option>03:08</option><option>03:09</option><option>03:10</option><option>03:11</option><option>03:12</option><option>03:13</option><option>03:14</option><option>03:15</option><option>03:16</option><option>03:17</option><option>03:18</option><option>03:19</option><option>03:20</option><option>03:21</option><option>03:22</option><option>03:23</option><option>03:24</option><option>03:25</option><option>03:26</option><option>03:27</option><option>03:28</option><option>03:29</option><option>03:30</option><option>03:31</option><option>03:32</option><option>03:33</option><option>03:34</option><option>03:35</option><option>03:36</option><option>03:37</option><option>03:38</option><option>03:39</option><option>03:40</option><option>03:41</option><option>03:42</option><option>03:43</option><option>03:44</option><option>03:45</option><option>03:46</option><option>03:47</option><option>03:48</option><option>03:49</option><option>03:50</option><option>03:51</option><option>03:52</option><option>03:53</option><option>03:54</option><option>03:55</option><option>03:56</option><option>03:57</option><option>03:58</option><option>03:59</option><option>04:00</option><option>04:01</option><option>04:02</option><option>04:03</option><option>04:04</option><option>04:05</option><option>04:06</option><option>04:07</option><option>04:08</option><option>04:09</option><option>04:10</option><option>04:11</option><option>04:12</option><option>04:13</option><option>04:14</option><option>04:15</option><option>04:16</option><option>04:17</option><option>04:18</option><option>04:19</option><option>04:20</option><option>04:21</option><option>04:22</option><option>04:23</option><option>04:24</option><option>04:25</option><option>04:26</option><option>04:27</option><option>04:28</option><option>04:29</option><option>04:30</option><option>04:31</option><option>04:32</option><option>04:33</option><option>04:34</option><option>04:35</option><option>04:36</option><option>04:37</option><option>04:38</option><option>04:39</option><option>04:40</option><option>04:41</option><option>04:42</option><option>04:43</option><option>04:44</option><option>04:45</option><option>04:46</option><option>04:47</option><option>04:48</option><option>04:49</option><option>04:50</option><option>04:51</option><option>04:52</option><option>04:53</option><option>04:54</option><option>04:55</option><option>04:56</option><option>04:57</option><option>04:58</option><option>04:59</option><option>05:00</option><option>05:01</option><option>05:02</option><option>05:03</option><option>05:04</option><option>05:05</option><option>05:06</option><option>05:07</option><option>05:08</option><option>05:09</option><option>05:10</option><option>05:11</option><option>05:12</option><option>05:13</option><option>05:14</option><option>05:15</option><option>05:16</option><option>05:17</option><option>05:18</option><option>05:19</option><option>05:20</option><option>05:21</option><option>05:22</option><option>05:23</option><option>05:24</option><option>05:25</option><option>05:26</option><option>05:27</option><option>05:28</option><option>05:29</option><option>05:30</option><option>05:31</option><option>05:32</option><option>05:33</option><option>05:34</option><option>05:35</option><option>05:36</option><option>05:37</option><option>05:38</option><option>05:39</option><option>05:40</option><option>05:41</option><option>05:42</option><option>05:43</option><option>05:44</option><option>05:45</option><option>05:46</option><option>05:47</option><option>05:48</option><option>05:49</option><option>05:50</option><option>05:51</option><option>05:52</option><option>05:53</option><option>05:54</option><option>05:55</option><option>05:56</option><option>05:57</option><option>05:58</option><option>05:59</option><option>06:00</option><option>06:01</option><option>06:02</option><option>06:03</option><option>06:04</option><option>06:05</option><option>06:06</option><option>06:07</option><option>06:08</option><option>06:09</option><option>06:10</option><option>06:11</option><option>06:12</option><option>06:13</option><option>06:14</option><option>06:15</option><option>06:16</option><option>06:17</option><option>06:18</option><option>06:19</option><option>06:20</option><option>06:21</option><option>06:22</option><option>06:23</option><option>06:24</option><option>06:25</option><option>06:26</option><option>06:27</option><option>06:28</option><option>06:29</option><option>06:30</option><option>06:31</option><option>06:32</option><option>06:33</option><option>06:34</option><option>06:35</option><option>06:36</option><option>06:37</option><option>06:38</option><option>06:39</option><option>06:40</option><option>06:41</option><option>06:42</option><option>06:43</option><option>06:44</option><option>06:45</option><option>06:46</option><option>06:47</option><option>06:48</option><option>06:49</option><option>06:50</option><option>06:51</option><option>06:52</option><option>06:53</option><option>06:54</option><option>06:55</option><option>06:56</option><option>06:57</option><option>06:58</option><option>06:59</option><option>07:00</option><option>07:01</option><option>07:02</option><option>07:03</option><option>07:04</option><option>07:05</option><option>07:06</option><option>07:07</option><option>07:08</option><option>07:09</option><option>07:10</option><option>07:11</option><option selected>07:12</option><option>07:13</option><option>07:14</option><option>07:15</option><option>07:16</option><option>07:17</option><option>07:18</option><option>07:19</option><option>07:20</option><option>07:21</option><option>07:22</option><option>07:23</option><option>07:24</option><option>07:25</option><option>07:26</option><option>07:27</option><option>07:28</option><option>07:29</option><option>07:30</option><option>07:31</option><option>07:32</option><option>07:33</option><option>07:34</option><option>07:35</option><option>07:36</option><option>07:37</option><option>07:38</option><option>07:39</option><option>07:40</option><option>07:41</option><option>07:42</option><option>07:43</option><option>07:44</option><option>07:45</option><option>07:46</option><option>07:47</option><option>07:48</option><option>07:49</option><option>07:50</option><option>07:51</option><option>07:52</option><option>07:53</option><option>07:54</option><option>07:55</option><option>07:56</option><option>07:57</option><option>07:58</option><option>07:59</option><option>08:00</option><option>08:01</option><option>08:02</option><option>08:03</option><option>08:04</option><option>08:05</option><option>08:06</option><option>08:07</option><option>08:08</option><option>08:09</option><option>08:10</option><option>08:11</option><option>08:12</option><option>08:13</option><option>08:14</option><option>08:15</option><option>08:16</option><option>08:17</option><option>08:18</option><option>08:19</option><option>08:20</option><option>08:21</option><option>08:22</option><option>08:23</option><option>08:24</option><option>08:25</option><option>08:26</option><option>08:27</option><option>08:28</option><option>08:29</option><option>08:30</option><option>08:31</option><option>08:32</option><option>08:33</option><option>08:34</option><option>08:35</option><option>08:36</option><option>08:37</option><option>08:38</option><option>08:39</option><option>08:40</option><option>08:41</option><option>08:42</option><option>08:43</option><option>08:44</option><option>08:45</option><option>08:46</option><option>08:47</option><option>08:48</option><option>08:49</option><option>08:50</option><option>08:51</option><option>08:52</option><option>08:53</option><option>08:54</option><option>08:55</option><option>08:56</option><option>08:57</option><option>08:58</option><option>08:59</option><option>09:00</option><option>09:01</option><option>09:02</option><option>09:03</option><option>09:04</option><option>09:05</option><option>09:06</option><option>09:07</option><option>09:08</option><option>09:09</option><option>09:10</option><option>09:11</option><option>09:12</option><option>09:13</option><option>09:14</option><option>09:15</option><option>09:16</option><option>09:17</option><option>09:18</option><option>09:19</option><option>09:20</option><option>09:21</option><option>09:22</option><option>09:23</option><option>09:24</option><option>09:25</option><option>09:26</option><option>09:27</option><option>09:28</option><option>09:29</option><option>09:30</option><option>09:31</option><option>09:32</option><option>09:33</option><option>09:34</option><option>09:35</option><option>09:36</option><option>09:37</option><option>09:38</option><option>09:39</option><option>09:40</option><option>09:41</option><option>09:42</option><option>09:43</option><option>09:44</option><option>09:45</option><option>09:46</option><option>09:47</option><option>09:48</option><option>09:49</option><option>09:50</option><option>09:51</option><option>09:52</option><option>09:53</option><option>09:54</option><option>09:55</option><option>09:56</option><option>09:57</option><option>09:58</option><option>09:59</option><option>10:00</option><option>10:01</option><option>10:02</option><option>10:03</option><option>10:04</option><option>10:05</option><option>10:06</option><option>10:07</option><option>10:08</option><option>10:09</option><option>10:10</option><option>10:11</option><option>10:12</option><option>10:13</option><option>10:14</option><option>10:15</option><option>10:16</option><option>10:17</option><option>10:18</option><option>10:19</option><option>10:20</option><option>10:21</option><option>10:22</option><option>10:23</option><option>10:24</option><option>10:25</option><option>10:26</option><option>10:27</option><option>10:28</option><option>10:29</option><option>10:30</option><option>10:31</option><option>10:32</option><option>10:33</option><option>10:34</option><option>10:35</option><option>10:36</option><option>10:37</option><option>10:38</option><option>10:39</option><option>10:40</option><option>10:41</option><option>10:42</option><option>10:43</option><option>10:44</option><option>10:45</option><option>10:46</option><option>10:47</option><option>10:48</option><option>10:49</option><option>10:50</option><option>10:51</option><option>10:52</option><option>10:53</option><option>10:54</option><option>10:55</option><option>10:56</option><option>10:57</option><option>10:58</option><option>10:59</option><option>11:00</option><option>11:01</option><option>11:02</option><option>11:03</option><option>11:04</option><option>11:05</option><option>11:06</option><option>11:07</option><option>11:08</option><option>11:09</option><option>11:10</option><option>11:11</option><option>11:12</option><option>11:13</option><option>11:14</option><option>11:15</option><option>11:16</option><option>11:17</option><option>11:18</option><option>11:19</option><option>11:20</option><option>11:21</option><option>11:22</option><option>11:23</option><option>11:24</option><option>11:25</option><option>11:26</option><option>11:27</option><option>11:28</option><option>11:29</option><option>11:30</option><option>11:31</option><option>11:32</option><option>11:33</option><option>11:34</option><option>11:35</option><option>11:36</option><option>11:37</option><option>11:38</option><option>11:39</option><option>11:40</option><option>11:41</option><option>11:42</option><option>11:43</option><option>11:44</option><option>11:45</option><option>11:46</option><option>11:47</option><option>11:48</option><option>11:49</option><option>11:50</option><option>11:51</option><option>11:52</option><option>11:53</option><option>11:54</option><option>11:55</option><option>11:56</option><option>11:57</option><option>11:58</option><option>11:59</option><option>12:00</option><option>12:01</option><option>12:02</option><option>12:03</option><option>12:04</option><option>12:05</option><option>12:06</option><option>12:07</option><option>12:08</option><option>12:09</option><option>12:10</option><option>12:11</option><option>12:12</option><option>12:13</option><option>12:14</option><option>12:15</option><option>12:16</option><option>12:17</option><option>12:18</option><option>12:19</option><option>12:20</option><option>12:21</option><option>12:22</option><option>12:23</option><option>12:24</option><option>12:25</option><option>12:26</option><option>12:27</option><option>12:28</option><option>12:29</option><option>12:30</option><option>12:31</option><option>12:32</option><option>12:33</option><option>12:34</option><option>12:35</option><option>12:36</option><option>12:37</option><option>12:38</option><option>12:39</option><option>12:40</option><option>12:41</option><option>12:42</option><option>12:43</option><option>12:44</option><option>12:45</option><option>12:46</option><option>12:47</option><option>12:48</option><option>12:49</option><option>12:50</option><option>12:51</option><option>12:52</option><option>12:53</option><option>12:54</option><option>12:55</option><option>12:56</option><option>12:57</option><option>12:58</option><option>12:59</option><option>13:00</option><option>13:01</option><option>13:02</option><option>13:03</option><option>13:04</option><option>13:05</option><option>13:06</option><option>13:07</option><option>13:08</option><option>13:09</option><option>13:10</option><option>13:11</option><option>13:12</option><option>13:13</option><option>13:14</option><option>13:15</option><option>13:16</option><option>13:17</option><option>13:18</option><option>13:19</option><option>13:20</option><option>13:21</option><option>13:22</option><option>13:23</option><option>13:24</option><option>13:25</option><option>13:26</option><option>13:27</option><option>13:28</option><option>13:29</option><option>13:30</option><option>13:31</option><option>13:32</option><option>13:33</option><option>13:34</option><option>13:35</option><option>13:36</option><option>13:37</option><option>13:38</option><option>13:39</option><option>13:40</option><option>13:41</option><option>13:42</option><option>13:43</option><option>13:44</option><option>13:45</option><option>13:46</option><option>13:47</option><option>13:48</option><option>13:49</option><option>13:50</option><option>13:51</option><option>13:52</option><option>13:53</option><option>13:54</option><option>13:55</option><option>13:56</option><option>13:57</option><option>13:58</option><option>13:59</option><option>14:00</option>
                        </select>
                    </div>

                    <div class="form-group row"><label class="col-3" for="actual_time">Actual time</label>
                        <select name="actual_time" id="actual_time" class="form-control col">
                            <option>03:00</option><option>03:01</option><option>03:02</option><option>03:03</option><option>03:04</option><option>03:05</option><option>03:06</option><option>03:07</option><option>03:08</option><option>03:09</option><option>03:10</option><option>03:11</option><option>03:12</option><option>03:13</option><option>03:14</option><option>03:15</option><option>03:16</option><option>03:17</option><option>03:18</option><option>03:19</option><option>03:20</option><option>03:21</option><option>03:22</option><option>03:23</option><option>03:24</option><option>03:25</option><option>03:26</option><option>03:27</option><option>03:28</option><option>03:29</option><option>03:30</option><option>03:31</option><option>03:32</option><option>03:33</option><option>03:34</option><option>03:35</option><option>03:36</option><option>03:37</option><option>03:38</option><option>03:39</option><option>03:40</option><option>03:41</option><option>03:42</option><option>03:43</option><option>03:44</option><option>03:45</option><option>03:46</option><option>03:47</option><option>03:48</option><option>03:49</option><option>03:50</option><option>03:51</option><option>03:52</option><option>03:53</option><option>03:54</option><option>03:55</option><option>03:56</option><option>03:57</option><option>03:58</option><option>03:59</option><option>04:00</option><option>04:01</option><option>04:02</option><option>04:03</option><option>04:04</option><option>04:05</option><option>04:06</option><option>04:07</option><option>04:08</option><option>04:09</option><option>04:10</option><option>04:11</option><option>04:12</option><option>04:13</option><option>04:14</option><option>04:15</option><option>04:16</option><option>04:17</option><option>04:18</option><option>04:19</option><option>04:20</option><option>04:21</option><option>04:22</option><option>04:23</option><option>04:24</option><option>04:25</option><option>04:26</option><option>04:27</option><option>04:28</option><option>04:29</option><option>04:30</option><option>04:31</option><option>04:32</option><option>04:33</option><option>04:34</option><option>04:35</option><option>04:36</option><option>04:37</option><option>04:38</option><option>04:39</option><option>04:40</option><option>04:41</option><option>04:42</option><option>04:43</option><option>04:44</option><option>04:45</option><option>04:46</option><option>04:47</option><option>04:48</option><option>04:49</option><option>04:50</option><option>04:51</option><option>04:52</option><option>04:53</option><option>04:54</option><option>04:55</option><option>04:56</option><option>04:57</option><option>04:58</option><option>04:59</option><option>05:00</option><option>05:01</option><option>05:02</option><option>05:03</option><option>05:04</option><option>05:05</option><option>05:06</option><option>05:07</option><option>05:08</option><option>05:09</option><option>05:10</option><option>05:11</option><option>05:12</option><option>05:13</option><option>05:14</option><option>05:15</option><option>05:16</option><option>05:17</option><option>05:18</option><option>05:19</option><option>05:20</option><option>05:21</option><option>05:22</option><option>05:23</option><option>05:24</option><option>05:25</option><option>05:26</option><option>05:27</option><option>05:28</option><option>05:29</option><option>05:30</option><option>05:31</option><option>05:32</option><option>05:33</option><option>05:34</option><option>05:35</option><option>05:36</option><option>05:37</option><option>05:38</option><option>05:39</option><option>05:40</option><option>05:41</option><option>05:42</option><option>05:43</option><option>05:44</option><option>05:45</option><option>05:46</option><option>05:47</option><option>05:48</option><option>05:49</option><option>05:50</option><option>05:51</option><option>05:52</option><option>05:53</option><option>05:54</option><option>05:55</option><option>05:56</option><option>05:57</option><option>05:58</option><option>05:59</option><option>06:00</option><option>06:01</option><option>06:02</option><option>06:03</option><option>06:04</option><option>06:05</option><option>06:06</option><option>06:07</option><option>06:08</option><option>06:09</option><option>06:10</option><option>06:11</option><option>06:12</option><option>06:13</option><option>06:14</option><option>06:15</option><option>06:16</option><option>06:17</option><option>06:18</option><option>06:19</option><option>06:20</option><option>06:21</option><option>06:22</option><option>06:23</option><option>06:24</option><option>06:25</option><option>06:26</option><option>06:27</option><option>06:28</option><option>06:29</option><option>06:30</option><option>06:31</option><option>06:32</option><option>06:33</option><option>06:34</option><option>06:35</option><option>06:36</option><option>06:37</option><option>06:38</option><option>06:39</option><option>06:40</option><option>06:41</option><option>06:42</option><option>06:43</option><option>06:44</option><option>06:45</option><option>06:46</option><option selected>06:47</option><option>06:48</option><option>06:49</option><option>06:50</option><option>06:51</option><option>06:52</option><option>06:53</option><option>06:54</option><option>06:55</option><option>06:56</option><option>06:57</option><option>06:58</option><option>06:59</option><option>07:00</option><option>07:01</option><option>07:02</option><option>07:03</option><option>07:04</option><option>07:05</option><option>07:06</option><option>07:07</option><option>07:08</option><option>07:09</option><option>07:10</option><option>07:11</option><option>07:12</option><option>07:13</option><option>07:14</option><option>07:15</option><option>07:16</option><option>07:17</option><option>07:18</option><option>07:19</option><option>07:20</option><option>07:21</option><option>07:22</option><option>07:23</option><option>07:24</option><option>07:25</option><option>07:26</option><option>07:27</option><option>07:28</option><option>07:29</option><option>07:30</option><option>07:31</option><option>07:32</option><option>07:33</option><option>07:34</option><option>07:35</option><option>07:36</option><option>07:37</option><option>07:38</option><option>07:39</option><option>07:40</option><option>07:41</option><option>07:42</option><option>07:43</option><option>07:44</option><option>07:45</option><option>07:46</option><option>07:47</option><option>07:48</option><option>07:49</option><option>07:50</option><option>07:51</option><option>07:52</option><option>07:53</option><option>07:54</option><option>07:55</option><option>07:56</option><option>07:57</option><option>07:58</option><option>07:59</option><option>08:00</option><option>08:01</option><option>08:02</option><option>08:03</option><option>08:04</option><option>08:05</option><option>08:06</option><option>08:07</option><option>08:08</option><option>08:09</option><option>08:10</option><option>08:11</option><option>08:12</option><option>08:13</option><option>08:14</option><option>08:15</option><option>08:16</option><option>08:17</option><option>08:18</option><option>08:19</option><option>08:20</option><option>08:21</option><option>08:22</option><option>08:23</option><option>08:24</option><option>08:25</option><option>08:26</option><option>08:27</option><option>08:28</option><option>08:29</option><option>08:30</option><option>08:31</option><option>08:32</option><option>08:33</option><option>08:34</option><option>08:35</option><option>08:36</option><option>08:37</option><option>08:38</option><option>08:39</option><option>08:40</option><option>08:41</option><option>08:42</option><option>08:43</option><option>08:44</option><option>08:45</option><option>08:46</option><option>08:47</option><option>08:48</option><option>08:49</option><option>08:50</option><option>08:51</option><option>08:52</option><option>08:53</option><option>08:54</option><option>08:55</option><option>08:56</option><option>08:57</option><option>08:58</option><option>08:59</option><option>09:00</option><option>09:01</option><option>09:02</option><option>09:03</option><option>09:04</option><option>09:05</option><option>09:06</option><option>09:07</option><option>09:08</option><option>09:09</option><option>09:10</option><option>09:11</option><option>09:12</option><option>09:13</option><option>09:14</option><option>09:15</option><option>09:16</option><option>09:17</option><option>09:18</option><option>09:19</option><option>09:20</option><option>09:21</option><option>09:22</option><option>09:23</option><option>09:24</option><option>09:25</option><option>09:26</option><option>09:27</option><option>09:28</option><option>09:29</option><option>09:30</option><option>09:31</option><option>09:32</option><option>09:33</option><option>09:34</option><option>09:35</option><option>09:36</option><option>09:37</option><option>09:38</option><option>09:39</option><option>09:40</option><option>09:41</option><option>09:42</option><option>09:43</option><option>09:44</option><option>09:45</option><option>09:46</option><option>09:47</option><option>09:48</option><option>09:49</option><option>09:50</option><option>09:51</option><option>09:52</option><option>09:53</option><option>09:54</option><option>09:55</option><option>09:56</option><option>09:57</option><option>09:58</option><option>09:59</option><option>10:00</option><option>10:01</option><option>10:02</option><option>10:03</option><option>10:04</option><option>10:05</option><option>10:06</option><option>10:07</option><option>10:08</option><option>10:09</option><option>10:10</option><option>10:11</option><option>10:12</option><option>10:13</option><option>10:14</option><option>10:15</option><option>10:16</option><option>10:17</option><option>10:18</option><option>10:19</option><option>10:20</option><option>10:21</option><option>10:22</option><option>10:23</option><option>10:24</option><option>10:25</option><option>10:26</option><option>10:27</option><option>10:28</option><option>10:29</option><option>10:30</option><option>10:31</option><option>10:32</option><option>10:33</option><option>10:34</option><option>10:35</option><option>10:36</option><option>10:37</option><option>10:38</option><option>10:39</option><option>10:40</option><option>10:41</option><option>10:42</option><option>10:43</option><option>10:44</option><option>10:45</option><option>10:46</option><option>10:47</option><option>10:48</option><option>10:49</option><option>10:50</option><option>10:51</option><option>10:52</option><option>10:53</option><option>10:54</option><option>10:55</option><option>10:56</option><option>10:57</option><option>10:58</option><option>10:59</option><option>11:00</option><option>11:01</option><option>11:02</option><option>11:03</option><option>11:04</option><option>11:05</option><option>11:06</option><option>11:07</option><option>11:08</option><option>11:09</option><option>11:10</option><option>11:11</option><option>11:12</option><option>11:13</option><option>11:14</option><option>11:15</option><option>11:16</option><option>11:17</option><option>11:18</option><option>11:19</option><option>11:20</option><option>11:21</option><option>11:22</option><option>11:23</option><option>11:24</option><option>11:25</option><option>11:26</option><option>11:27</option><option>11:28</option><option>11:29</option><option>11:30</option><option>11:31</option><option>11:32</option><option>11:33</option><option>11:34</option><option>11:35</option><option>11:36</option><option>11:37</option><option>11:38</option><option>11:39</option><option>11:40</option><option>11:41</option><option>11:42</option><option>11:43</option><option>11:44</option><option>11:45</option><option>11:46</option><option>11:47</option><option>11:48</option><option>11:49</option><option>11:50</option><option>11:51</option><option>11:52</option><option>11:53</option><option>11:54</option><option>11:55</option><option>11:56</option><option>11:57</option><option>11:58</option><option>11:59</option><option>12:00</option><option>12:01</option><option>12:02</option><option>12:03</option><option>12:04</option><option>12:05</option><option>12:06</option><option>12:07</option><option>12:08</option><option>12:09</option><option>12:10</option><option>12:11</option><option>12:12</option><option>12:13</option><option>12:14</option><option>12:15</option><option>12:16</option><option>12:17</option><option>12:18</option><option>12:19</option><option>12:20</option><option>12:21</option><option>12:22</option><option>12:23</option><option>12:24</option><option>12:25</option><option>12:26</option><option>12:27</option><option>12:28</option><option>12:29</option><option>12:30</option><option>12:31</option><option>12:32</option><option>12:33</option><option>12:34</option><option>12:35</option><option>12:36</option><option>12:37</option><option>12:38</option><option>12:39</option><option>12:40</option><option>12:41</option><option>12:42</option><option>12:43</option><option>12:44</option><option>12:45</option><option>12:46</option><option>12:47</option><option>12:48</option><option>12:49</option><option>12:50</option><option>12:51</option><option>12:52</option><option>12:53</option><option>12:54</option><option>12:55</option><option>12:56</option><option>12:57</option><option>12:58</option><option>12:59</option><option>13:00</option><option>13:01</option><option>13:02</option><option>13:03</option><option>13:04</option><option>13:05</option><option>13:06</option><option>13:07</option><option>13:08</option><option>13:09</option><option>13:10</option><option>13:11</option><option>13:12</option><option>13:13</option><option>13:14</option><option>13:15</option><option>13:16</option><option>13:17</option><option>13:18</option><option>13:19</option><option>13:20</option><option>13:21</option><option>13:22</option><option>13:23</option><option>13:24</option><option>13:25</option><option>13:26</option><option>13:27</option><option>13:28</option><option>13:29</option><option>13:30</option><option>13:31</option><option>13:32</option><option>13:33</option><option>13:34</option><option>13:35</option><option>13:36</option><option>13:37</option><option>13:38</option><option>13:39</option><option>13:40</option><option>13:41</option><option>13:42</option><option>13:43</option><option>13:44</option><option>13:45</option><option>13:46</option><option>13:47</option><option>13:48</option><option>13:49</option><option>13:50</option><option>13:51</option><option>13:52</option><option>13:53</option><option>13:54</option><option>13:55</option><option>13:56</option><option>13:57</option><option>13:58</option><option>13:59</option><option>14:00</option>
                        </select>
                    </div>

                    <input type="hidden" name="athlete_id" id="athlete_id" class="form-control col">

                    <input name="predicted_time_parsed" type="hidden" id="predicted_time_parsed">

                    <input name="actual_time_parsed" type="hidden" id="actual_time_parsed">

                    <input type="submit" class="btn btn-primary" id="submit">
                </form>
            </div>
        </div>
    </div>
    <script>
        $(function() {

            $('#date').val(new Date().toISOString().slice(0,10));
            resetForm();
            updateParsedValues();

            $('#submit').on('click', function(e) {
                $('#save-success, #save-error').addClass('d-none');
                e.preventDefault();
                $.post('/api/public/index.php/magicmile', $('form').serialize(), function() {
                    $('#save-success').removeClass('d-none');
                    resetForm();
                }).fail(function(response) {
                    showErrors(response);
                });
            })

            $('#predicted_time, #actual_time').on('change', function() {
                updateParsedValues();
            });

            $('#predicted_time').on('change', function() {
                $('#actual_time').val($('#predicted_time').val());
            });

            function updateParsedValues() {
                var predictedTime = $('#predicted_time').val();
                var predictedTimeSeconds = Number(predictedTime.split(':')[0] * 60) + Number(predictedTime.split(':')[1]);
                var actualTime = $('#actual_time').val();
                var actualTimeSeconds = Number(actualTime.split(':')[0] * 60) + Number(actualTime.split(':')[1]);

                $('#predicted_time_parsed').val(predictedTimeSeconds);
                $('#actual_time_parsed').val(actualTimeSeconds);
            }

            $('#first_name, #last_name').on('change, keyup', function() {
                if ($('#first_name').val().length < 2 && $('#last_name').val().length < 2) return;

                var search = $('#first_name').val() + ' ' + $('#last_name').val();

                $.get('/api/public/index.php/athletes?search=' + search, function(results) {
                    var athleteList
                    $('#athlete-search-results').html('<h2 class="h5">Select an athlete</h2><ul class="list-inline small">' + results.map(result => {
                        var categoryString = result.category ? ` (${result.category})` : '';
                        return `<li class="list-inline-item"><a href="#" onclick="selectAthlete(event, ${result.id}, '${result.first_name}', '${result.last_name}', '${result.gender}', '${result.category}')">
                            ${result.first_name} ${result.last_name}${categoryString}
                            </a></li>`;
                    }).join('') + '</ul>');
                    $('#athlete-search-results').show();
                });
            });
        });

        function selectAthlete(event, id, firstName, lastName, gender, category) {
            event.preventDefault();
            $('#athlete_id').val(id);
            $('#first_name').val(firstName);
            $('#last_name').val(lastName);
            $('#category').val(category);
            $('#gender').val(gender);
            $('#athlete-search-results').hide();
            $('#predicted_time').focus();
        }

        function resetForm() {
            $('#athlete_id').val('');
            $('#first_name').val('');
            $('#last_name').val('');
            $('#first_name').focus();
        }

        function showErrors(response) {
            var errors = response.responseJSON;
            if (errors && Object.keys(errors).length) {
                $('#error-messages').html('');
                Object.keys(errors).forEach(function(key, index) {
                        $('#error-messages').append(`<li><a href="#${key}">${errors[key]}</a></li>`);
                });
                $('#error-messages').wrapInner('<ul></ul>');
            } else {
                $('#error-messages').html(`<strong>${response.status}</strong> ${response.statusText}`);
            }
            $('#save-error').removeClass('d-none');
        }
    </script>
</body>
</html>



