// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import fs from 'fs';


const data = fs.readFileSync('/home/nick/tasks.log').toString();

//console.log(data);
//console.log(Parser.parseTasks(data))



const testCases = [
    {name: 'empty 1',
     log: '',
     expect: {
	 tasks: {},
	 report: {},
     },
    },
    
    {name: 'empty 2',
     log: '1\tinit\t\t100\t',
     expect: {
	 tasks: {},
	 report: {},
     },
    },

    {name: 'real case 2',
     log: `1	init		2021-09-01T21:09:14.858Z
1	switch	2021-09-01T21:09:14.858Z	2021-09-01T21:16:16.008Z	ICA data update
1	start	2021-09-01T21:16:16.008Z	2021-09-01T21:16:16.016Z	
1	mark	2021-09-01T21:16:16.016Z	2021-09-01T21:17:13.285Z	
1	mark	2021-09-01T21:17:13.285Z	2021-09-01T21:18:10.507Z	
1	mark	2021-09-01T21:18:10.507Z	2021-09-01T21:19:07.582Z	
1	mark	2021-09-01T21:19:07.582Z	2021-09-01T21:20:04.926Z	
1	mark	2021-09-01T21:20:04.926Z	2021-09-01T21:21:02.230Z	
1	mark	2021-09-01T21:21:02.230Z	2021-09-01T21:21:59.592Z	
1	mark	2021-09-01T21:21:59.592Z	2021-09-01T21:22:56.936Z	
1	mark	2021-09-01T21:22:56.936Z	2021-09-01T21:23:54.279Z	
1	mark	2021-09-01T21:23:54.279Z	2021-09-01T21:24:51.621Z	
1	mark	2021-09-01T21:24:51.621Z	2021-09-01T21:25:48.958Z	
1	mark	2021-09-01T21:25:48.958Z	2021-09-01T21:26:46.300Z	
1	mark	2021-09-01T21:26:46.300Z	2021-09-01T21:27:43.646Z	
1	mark	2021-09-01T21:27:43.646Z	2021-09-01T21:28:40.966Z	
1	mark	2021-09-01T21:28:40.966Z	2021-09-01T21:29:38.308Z	
1	mark	2021-09-01T21:29:38.308Z	2021-09-01T21:30:35.646Z	
1	mark	2021-09-01T21:30:35.646Z	2021-09-01T21:31:32.692Z	
1	mark	2021-09-01T21:31:32.692Z	2021-09-01T21:32:30.033Z	
1	mark	2021-09-01T21:32:30.033Z	2021-09-01T21:33:27.357Z	
1	mark	2021-09-01T21:33:27.357Z	2021-09-01T21:34:24.539Z	
1	mark	2021-09-01T21:34:24.539Z	2021-09-01T21:35:21.887Z	
1	mark	2021-09-01T21:35:21.887Z	2021-09-01T21:36:19.229Z	
1	mark	2021-09-01T21:36:19.229Z	2021-09-01T21:37:16.568Z	
1	mark	2021-09-01T21:37:16.568Z	2021-09-01T21:38:13.906Z	
1	mark	2021-09-01T21:38:13.906Z	2021-09-01T21:39:11.248Z	
1	mark	2021-09-01T21:39:11.248Z	2021-09-01T21:40:08.439Z	
1	stop	2021-09-01T21:40:08.439Z	2021-09-01T21:40:12.619Z	
1	start	2021-09-01T21:40:12.619Z	2021-09-01T21:45:40.032Z	
1	stop	2021-09-01T21:45:40.032Z	2021-09-01T21:45:41.707Z
1	init		2021-09-01T21:47:41.740Z
1	switch	2021-09-01T21:47:41.740Z	2021-09-01T21:49:17.236Z	ICA data update
1	start	2021-09-01T21:49:17.236Z	2021-09-01T21:49:17.245Z	
1	stop	2021-09-01T21:49:17.245Z	2021-09-01T21:49:19.283Z	
1	start	2021-09-01T21:49:19.283Z	2021-09-01T21:49:22.231Z	
1	stop	2021-09-01T21:49:22.231Z	2021-09-01T21:49:24.046Z	
1	init		2021-09-01T21:55:31.912Z
1	init		2021-09-01T21:57:36.167Z
1	init		2021-09-01T21:58:03.365Z
     `,
     expect: {
	 tasks: {'ICA data update': 1442 },
	 report: {
	     '2021-09-01T00:00:00+0100': {
		 'ICA data update': '00:24:02',
		 'total': '00:24:02'
	     }
	 },
     },
    },

    {name: 'real case 3',
     log: `1	switch	2021-09-01T17:59:18.863Z	2021-09-01T19:43:57.960Z	ICA data update
1	init		2021-09-01T19:57:00.436Z
1	init		2021-09-01T20:12:45.055Z
1	init		2021-09-01T20:13:50.984Z
1	init		2021-09-01T20:14:23.373Z
1	init		2021-09-01T20:14:45.980Z
1	init		2021-09-01T20:15:25.721Z
1	init		2021-09-01T20:15:42.506Z
1	init		2021-09-01T20:16:19.291Z
1	init		2021-09-01T20:16:34.293Z
1	init		2021-09-01T20:16:47.235Z
1	init		2021-09-01T20:16:59.665Z
1	init		2021-09-01T20:17:54.866Z
1	init		2021-09-01T20:24:49.449Z
1	init		2021-09-01T20:26:40.961Z
1	init		2021-09-01T20:28:40.672Z
1	init		2021-09-01T20:29:41.851Z
1	init		2021-09-01T20:30:17.922Z
1	init		2021-09-01T20:30:43.662Z
1	init		2021-09-01T20:31:37.312Z
1	init		2021-09-01T20:32:12.529Z
1	init		2021-09-01T20:32:28.271Z
1	init		2021-09-01T20:32:57.818Z
1	init		2021-09-01T20:33:52.463Z
1	init		2021-09-01T20:36:19.418Z
1	init		2021-09-01T20:36:38.009Z
1	init		2021-09-01T20:38:42.076Z
1	init		2021-09-01T20:39:12.504Z
1	init		2021-09-01T20:41:10.907Z
1	init		2021-09-01T20:44:00.118Z
1	init		2021-09-01T20:45:02.713Z
1	init		2021-09-01T20:45:38.538Z
1	init		2021-09-01T20:49:27.599Z
1	init		2021-09-01T20:54:35.882Z
1	init		2021-09-01T20:55:18.984Z
1	init		2021-09-01T21:00:02.236Z
1	init		2021-09-01T21:00:22.413Z
1	init		2021-09-01T21:09:14.858Z
1	switch	2021-09-01T21:09:14.858Z	2021-09-01T21:16:16.008Z	ICA data update
1	start	2021-09-01T21:16:16.008Z	2021-09-01T21:16:16.016Z	
1	mark	2021-09-01T21:16:16.016Z	2021-09-01T21:17:13.285Z	
1	mark	2021-09-01T21:17:13.285Z	2021-09-01T21:18:10.507Z	
1	mark	2021-09-01T21:18:10.507Z	2021-09-01T21:19:07.582Z	
1	mark	2021-09-01T21:19:07.582Z	2021-09-01T21:20:04.926Z	
1	mark	2021-09-01T21:20:04.926Z	2021-09-01T21:21:02.230Z	
1	mark	2021-09-01T21:21:02.230Z	2021-09-01T21:21:59.592Z	
1	mark	2021-09-01T21:21:59.592Z	2021-09-01T21:22:56.936Z	
1	mark	2021-09-01T21:22:56.936Z	2021-09-01T21:23:54.279Z	
1	mark	2021-09-01T21:23:54.279Z	2021-09-01T21:24:51.621Z	
1	mark	2021-09-01T21:24:51.621Z	2021-09-01T21:25:48.958Z	
1	mark	2021-09-01T21:25:48.958Z	2021-09-01T21:26:46.300Z	
1	mark	2021-09-01T21:26:46.300Z	2021-09-01T21:27:43.646Z	
1	mark	2021-09-01T21:27:43.646Z	2021-09-01T21:28:40.966Z	
1	mark	2021-09-01T21:28:40.966Z	2021-09-01T21:29:38.308Z	
1	mark	2021-09-01T21:29:38.308Z	2021-09-01T21:30:35.646Z	
1	mark	2021-09-01T21:30:35.646Z	2021-09-01T21:31:32.692Z	
1	mark	2021-09-01T21:31:32.692Z	2021-09-01T21:32:30.033Z	
1	mark	2021-09-01T21:32:30.033Z	2021-09-01T21:33:27.357Z	
1	mark	2021-09-01T21:33:27.357Z	2021-09-01T21:34:24.539Z	
1	mark	2021-09-01T21:34:24.539Z	2021-09-01T21:35:21.887Z	
1	mark	2021-09-01T21:35:21.887Z	2021-09-01T21:36:19.229Z	
1	mark	2021-09-01T21:36:19.229Z	2021-09-01T21:37:16.568Z	
1	mark	2021-09-01T21:37:16.568Z	2021-09-01T21:38:13.906Z	
1	mark	2021-09-01T21:38:13.906Z	2021-09-01T21:39:11.248Z	
1	mark	2021-09-01T21:39:11.248Z	2021-09-01T21:40:08.439Z	
1	stop	2021-09-01T21:40:08.439Z	2021-09-01T21:40:12.619Z	
1	start	2021-09-01T21:40:12.619Z	2021-09-01T21:45:40.032Z	
1	stop	2021-09-01T21:45:40.032Z	2021-09-01T21:47:41.740Z	
1	switch	2021-09-01T21:47:41.740Z	2021-09-01T21:49:17.236Z	ICA data update
1	start	2021-09-01T21:49:17.236Z	2021-09-01T21:49:17.245Z	
1	stop	2021-09-01T21:49:17.245Z	2021-09-01T21:49:19.283Z	
1	start	2021-09-01T21:49:19.283Z	2021-09-01T21:49:22.231Z	
1	stop	2021-09-01T21:49:22.231Z	2021-09-01T21:49:24.046Z	
1	init		2021-09-01T21:55:31.912Z
1	init		2021-09-01T21:57:36.167Z
1	init		2021-09-01T21:58:03.365Z
1	init		2021-09-01T22:37:40.897Z
1	init		2021-09-02T07:52:06.165Z
1	switch	2021-09-02T07:52:06.165Z	2021-09-02T08:56:26.477Z	ICA data update
1	start	2021-09-02T08:56:26.477Z	2021-09-02T08:56:26.515Z	
1	mark	2021-09-02T08:56:26.515Z	2021-09-02T09:00:44.907Z	
1	mark	2021-09-02T09:00:44.907Z	2021-09-02T09:10:18.214Z	
1	mark	2021-09-02T09:10:18.214Z	2021-09-02T09:19:51.049Z	
1	mark	2021-09-02T09:19:51.049Z	2021-09-02T09:29:24.718Z	
1	mark	2021-09-02T09:29:24.718Z	2021-09-02T09:38:58.121Z	
1	mark	2021-09-02T09:38:58.121Z	2021-09-02T09:48:31.493Z	
1	stop	2021-09-02T09:48:31.493Z	2021-09-02T09:55:42.240Z	
1	init		2021-09-02T12:39:41.139Z
1	switch	2021-09-02T12:39:41.139Z	2021-09-02T13:20:54.413Z	ICA data update
1	start	2021-09-02T13:20:54.413Z	2021-09-02T13:26:54.435Z	
1	mark	2021-09-02T13:26:54.435Z	2021-09-02T13:31:55.748Z	
1	mark	2021-09-02T13:31:55.748Z	2021-09-02T13:41:29.047Z	
1	mark	2021-09-02T13:41:29.047Z	2021-09-02T13:51:02.796Z	
1	switch	2021-09-02T13:51:02.796Z	2021-09-02T13:52:32.641Z	ObO demo map site
1	mark	2021-09-02T13:52:32.641Z	2021-09-02T14:02:05.937Z	
1	mark	2021-09-02T14:02:05.937Z	2021-09-02T14:11:39.035Z	
1	mark	2021-09-02T14:11:39.035Z	2021-09-02T14:21:12.310Z	
1	mark	2021-09-02T14:21:12.310Z	2021-09-02T14:30:45.704Z	
1	mark	2021-09-02T14:30:45.704Z	2021-09-02T14:40:18.973Z	
1	mark	2021-09-02T14:40:18.973Z	2021-09-02T14:49:53.398Z	
1	mark	2021-09-02T14:49:53.398Z	2021-09-02T15:03:11.506Z	
1	mark	2021-09-02T15:03:11.506Z	2021-09-02T15:12:51.705Z	
1	mark	2021-09-02T15:12:51.705Z	2021-09-02T15:22:25.976Z	
1	mark	2021-09-02T15:22:25.976Z	2021-09-02T15:32:01.437Z	
1	mark	2021-09-02T15:32:01.437Z	2021-09-02T15:41:34.828Z	
1	mark	2021-09-02T15:41:34.828Z	2021-09-02T15:51:13.816Z	
1	mark	2021-09-02T15:51:13.816Z	2021-09-02T15:42:52.955Z	idle-discard
1	mark	2021-09-02T15:42:52.955Z	2021-09-02T16:00:51.556Z	
1	mark	2021-09-02T16:00:51.556Z	2021-09-02T16:10:25.907Z	
1	mark	2021-09-02T16:10:25.907Z	2021-09-02T16:19:59.527Z	
1	mark	2021-09-02T16:19:59.527Z	2021-09-02T16:29:33.213Z	
1	mark	2021-09-02T16:29:33.213Z	2021-09-02T16:39:06.074Z	
1	mark	2021-09-02T16:39:06.074Z	2021-09-02T16:48:38.839Z	
1	mark	2021-09-02T16:48:38.839Z	2021-09-02T16:58:13.710Z	
1	mark	2021-09-02T16:58:13.710Z	2021-09-02T17:07:52.375Z	
1	mark	2021-09-02T17:07:52.375Z	2021-09-02T17:17:26.572Z	
1	stop	2021-09-02T17:17:26.572Z	2021-09-02T17:14:07.044Z	idle-stop
1	start	2021-09-02T17:14:07.044Z	2021-09-02T22:50:55.418Z	
1	mark	2021-09-02T22:50:55.418Z	2021-09-02T22:59:01.275Z	
1	stop	2021-09-02T22:59:01.275Z	2021-09-02T23:04:45.931Z	
1	start	2021-09-02T23:04:45.931Z	2021-09-03T07:52:55.859Z	
1	mark	2021-09-03T07:52:55.859Z	2021-09-03T07:57:20.449Z	
1	mark	2021-09-03T07:57:20.449Z	2021-09-03T08:06:53.317Z	
1	mark	2021-09-03T08:06:53.317Z	2021-09-03T08:16:26.769Z	
1	mark	2021-09-03T08:16:26.769Z	2021-09-03T08:25:59.847Z	
1	init		2021-09-03T08:36:35.434Z
1	switch	2021-09-03T08:36:35.434Z	2021-09-03T09:00:48.318Z	ObO demo map site
1	start	2021-09-03T09:00:48.318Z	2021-09-03T09:00:48.372Z	
1	mark	2021-09-03T09:00:48.372Z	2021-09-03T09:06:17.103Z	
1	mark	2021-09-03T09:06:17.103Z	2021-09-03T09:15:49.779Z	
1	mark	2021-09-03T09:15:49.779Z	2021-09-03T09:25:22.822Z	
1	mark	2021-09-03T09:25:22.822Z	2021-09-03T09:34:55.797Z	
1	mark	2021-09-03T09:34:55.797Z	2021-09-03T09:44:29.615Z	
1	mark	2021-09-03T09:44:29.615Z	2021-09-03T09:54:02.507Z	
1	stop	2021-09-03T09:54:02.507Z	2021-09-03T09:54:57.615Z	
1	switch	2021-09-03T09:54:57.615Z	2021-09-03T15:36:00.674Z	Issue management
1	start	2021-09-03T15:36:00.674Z	2021-09-03T15:36:03.893Z	
1	switch	2021-09-03T15:36:03.893Z	2021-09-03T15:38:22.530Z	Add access for Alison mersey green
1	mark	2021-09-03T15:38:22.530Z	2021-09-03T15:47:53.948Z	
1	mark	2021-09-03T15:47:53.948Z	2021-09-03T15:57:26.129Z	
1	mark	2021-09-03T15:57:26.129Z	2021-09-03T16:06:59.843Z	
1	switch	2021-09-03T16:06:59.843Z	2021-09-03T16:12:56.191Z	Mutual Aid spreadsheet issue #2
1	mark	2021-09-03T16:12:56.191Z	2021-09-03T16:22:28.373Z	
1	mark	2021-09-03T16:22:28.373Z	2021-09-03T16:32:02.184Z	
1	mark	2021-09-03T16:32:02.184Z	2021-09-03T16:41:33.368Z	
1	switch	2021-09-03T16:41:33.368Z	2021-09-03T16:46:04.212Z	Ensure FB links show in mgp3
1	mark	2021-09-03T16:46:04.212Z	2021-09-03T16:55:35.664Z	
1	mark	2021-09-03T16:55:35.664Z	2021-09-03T17:05:08.952Z	
1	mark	2021-09-03T17:05:08.952Z	2021-09-03T17:14:42.010Z	
1	mark	2021-09-03T17:14:42.010Z	2021-09-03T17:24:15.066Z	
1	mark	2021-09-03T17:24:15.066Z	2021-09-03T17:33:47.532Z	
1	stop	2021-09-03T17:33:47.532Z	2021-09-03T17:43:07.801Z	
1	switch	2021-09-03T17:43:07.801Z	2021-09-06T13:55:06.357Z	Meeting with John
1	start	2021-09-06T13:55:06.357Z	2021-09-06T13:55:09.616Z	
1	stop	2021-09-06T13:55:09.616Z	2021-09-06T14:40:10.407Z	
# Here we switch to localtime
1	init		2021-09-07T13:16:17+01:00
1	init		2021-09-07T13:21:58+01:00
1	switch	2021-09-07T13:21:58+01:00	2021-09-07T13:22:22+01:00	Issue management
1	start	2021-09-07T13:22:22+01:00	2021-09-07T13:22:22+01:00	
1	stop	2021-09-07T13:22:22+01:00	2021-09-07T13:22:25+01:00	
1	init		2021-09-07T13:26:39+01:00
1	init		2021-09-07T13:27:03+01:00
1	switch	2021-09-07T13:27:03+01:00	2021-09-07T13:27:19+01:00	Issue management
1	start	2021-09-07T13:27:19+01:00	2021-09-07T13:27:19+01:00	
1	stop	2021-09-07T13:27:19+01:00	2021-09-07T13:27:20+01:00	
1	init		2021-09-07T13:37:01+0100
1	init		2021-09-07T13:44:08+0100
1	init		2021-09-07T14:50:06+0100
1	switch	2021-09-07T14:50:06+0100	2021-09-07T15:27:42+0100	Issue management
1	start	2021-09-07T15:27:42+0100	2021-09-07T15:27:42+0100	
1	stop	2021-09-07T15:27:42+0100	2021-09-07T15:27:44+0100	
1	switch	2021-09-07T15:27:44+0100	2021-09-07T15:29:22+0100	ICA youth data update
1	start	2021-09-07T15:29:22+0100	2021-09-07T15:29:27+0100	
1	mark	2021-09-07T15:29:27+0100	2021-09-07T15:39:01+0100	
1	mark	2021-09-07T15:39:01+0100	2021-09-07T15:48:35+0100	
1	mark	2021-09-07T15:48:35+0100	2021-09-07T15:58:09+0100	
1	mark	2021-09-07T15:58:09+0100	2021-09-07T16:07:43+0100	
1	mark	2021-09-07T16:07:43+0100	2021-09-07T16:17:17+0100	
1	mark	2021-09-07T16:17:17+0100	2021-09-07T16:26:50+0100	
1	mark	2021-09-07T16:26:50+0100	2021-09-07T16:36:23+0100	
1	switch	2021-09-07T16:36:23+0100	2021-09-07T16:44:21+0100	ICA data update
1	start	2021-09-07T16:44:21+0100	2021-09-07T16:44:21+0100	
1	mark	2021-09-07T16:44:21+0100	2021-09-07T16:51:37+0100	
1	mark	2021-09-07T16:51:37+0100	2021-09-07T17:01:10+0100	
1	mark	2021-09-07T17:01:10+0100	2021-09-07T17:10:46+0100	
1	mark	2021-09-07T17:10:46+0100	2021-09-07T17:20:19+0100	
1	mark	2021-09-07T17:20:19+0100	2021-09-07T17:29:52+0100	
1	mark	2021-09-07T17:29:52+0100	2021-09-07T17:39:26+0100	
1	stop	2021-09-07T17:39:26+0100	2021-09-07T17:48:16+0100	
1	switch	2021-09-07T17:48:16+0100	2021-09-08T09:05:00+0100	ObO correspondance
1	start	2021-09-08T09:05:00+0100	2021-09-08T09:05:03+0100	
1	stop	2021-09-08T09:05:03+0100	2021-09-08T09:23:05+0100	
1	init		2021-09-08T10:03:04+0100	0.1.0
1	init		2021-09-08T10:03:49+0100	0.1.0
1	init		2021-09-08T10:06:54+0100	0.1.0
1	init		2021-09-08T10:07:20+0100	0.1.0
1	init		2021-09-08T10:07:55+0100	0.1.0
1	switch	2021-09-08T10:07:55+0100	2021-09-08T10:08:02+0100	Issue management
1	start	2021-09-08T10:08:02+0100	2021-09-08T10:08:02+0100	
1	stop	2021-09-08T10:08:02+0100	2021-09-08T10:08:06+0100	
1	switch	2021-09-08T10:08:06+0100	2021-09-09T09:52:03+0100	ICA popup.js fix
1	start	2021-09-09T09:52:03+0100	2021-09-09T09:52:03+0100	
1	mark	2021-09-09T09:52:03+0100	2021-09-09T09:58:43+0100	
1	mark	2021-09-09T09:58:43+0100	2021-09-09T10:08:16+0100	
1	mark	2021-09-09T10:08:16+0100	2021-09-09T10:17:49+0100	
1	mark	2021-09-09T10:17:49+0100	2021-09-09T10:29:27+0100	
1	mark	2021-09-09T10:29:27+0100	2021-09-09T10:39:27+0100	
1	mark	2021-09-09T10:39:27+0100	2021-09-09T10:49:27+0100	
1	mark	2021-09-09T10:49:27+0100	2021-09-09T10:59:27+0100	
1	mark	2021-09-09T10:59:27+0100	2021-09-09T11:09:27+0100	
1	mark	2021-09-09T11:09:27+0100	2021-09-09T11:19:26+0100	
1	mark	2021-09-09T11:19:26+0100	2021-09-09T11:29:26+0100	
1	mark	2021-09-09T11:29:26+0100	2021-09-09T11:39:26+0100	
1	mark	2021-09-09T11:39:26+0100	2021-09-09T11:49:26+0100	
1	mark	2021-09-09T11:49:26+0100	2021-09-09T11:59:25+0100	
1	mark	2021-09-09T11:59:25+0100	2021-09-09T12:09:25+0100	
1	mark	2021-09-09T12:09:25+0100	2021-09-09T12:19:25+0100	
1	mark	2021-09-09T12:19:25+0100	2021-09-09T12:29:25+0100	
1	mark	2021-09-09T12:29:25+0100	2021-09-09T12:39:25+0100	
1	mark	2021-09-09T12:39:25+0100	2021-09-09T12:49:25+0100	
1	stop	2021-09-09T12:49:25+0100	2021-09-09T12:58:49+0100	
1	switch	2021-09-09T12:58:49+0100	2021-09-09T13:09:31+0100	Meeting with John and Colm
1	start	2021-09-09T13:09:31+0100	2021-09-09T13:09:37+0100	
1	stop	2021-09-09T13:09:37+0100	2021-09-09T13:45:40+0100	
1	switch	2021-09-09T13:45:40+0100	2021-09-09T15:30:40+0100	Meeting with Anna Thorne
1	start	2021-09-09T15:30:40+0100	2021-09-09T15:30:40+0100	
1	stop	2021-09-09T15:30:40+0100	2021-09-09T16:10:31+0100	
1	switch	2021-09-09T16:10:31+0100	2021-09-09T16:49:51+0100	ICA popup.js fix
1	start	2021-09-09T16:49:51+0100	2021-09-09T16:52:51+0100	
1	mark	2021-09-09T16:52:51+0100	2021-09-09T18:18:30+0100	
1	stop	2021-09-09T18:18:30+0100	2021-09-09T16:52:51+0100	idle-stop
1	init		2021-09-13T15:01:12+0100	0.1.0
1	init		2021-09-13T15:01:54+0100	0.1.0
1	init		2021-09-13T15:02:28+0100	0.1.0
1	init		2021-09-13T15:07:28+0100	0.1.0
`,
     expect: {
	 tasks: {
	     'ICA data update': 10401,
	     'ObO demo map site': 18158,
	     'Issue management': 10,
	     'Add access for Alison mersey green': 1717,
	     'Mutual Aid spreadsheet issue #2': 1717,
	     'Ensure FB links show in mgp3': 3424,
	     'Meeting with John': 2701,
	     'ICA youth data update': 4016,
	     'ObO correspondance': 1082,
	     'ICA popup.js fix': 11206,
	     'Meeting with John and Colm': 2163,
	     'Meeting with Anna Thorne': 2391
	 },
	 report: {
	     '2021-09-01T00:00:00+0100': {
		 'ICA data update': '00:26:02',
		 total: '00:26:02'
	     },
	     '2021-09-02T00:00:00+0100': {
		 'ObO demo map site': '03:35:24',
		 'ICA data update': '01:23:24',
		 total: '04:58:49'
	     },
	     '2021-09-03T00:00:00+0100': {
		 'ObO demo map site': '01:27:13',
		 'Ensure FB links show in mgp3': '00:57:03',
		 'Add access for Alison mersey green': '00:28:37',
		 'Mutual Aid spreadsheet issue #2': '00:28:37',
		 total: '03:21:31'
	     },
	     '2021-09-06T00:00:00+0100': {
		 'Meeting with John': '00:45:00',
		 total: '00:45:00'
	     },
	     '2021-09-07T00:00:00+0100': {
		 'ICA youth data update': '01:06:56',
		 'ICA data update': '01:03:55',
		 'Issue management': '00:00:06',
		 total: '02:10:57'

	     },
	     '2021-09-08T00:00:00+0100': {
		 'ObO correspondance': '00:18:02',
		 'Issue management': '00:00:04',
		 total: '00:18:06'
	     },
	     '2021-09-09T00:00:00+0100': {
		 'ICA popup.js fix': '03:06:46',
		 'Meeting with Anna Thorne': '00:39:51',
		 'Meeting with John and Colm': '00:36:03',
		 total: '04:22:40'
	     },
	 },
     },
    },

    {
	name: 'real case 4, trailing switch task 2',
	log: `1	init		2021-09-29T10:15:43+0100	0.1.0
1	switch	2021-09-29T10:15:43+0100	2021-09-29T17:15:45+0100	task 1
1	start	2021-09-29T17:15:45+0100	2021-09-29T17:15:45+0100	
1	mark	2021-09-29T17:15:45+0100	2021-09-29T18:50:43+0100	
1	stop	2021-09-29T18:50:43+0100	2021-09-29T18:56:52+0100	
1	start	2021-09-29T18:56:52+0100	2021-09-29T19:35:03+0100	
1	mark	2021-09-29T19:35:03+0100	2021-09-29T22:18:54+0100	
1	stop	2021-09-29T22:18:54+0100	2021-09-29T22:24:23+0100	
1	switch	2021-09-29T22:24:23+0100	2021-09-29T22:24:23+0100	task 2
`,
	expect: {
	    tasks: {
		'task 1': 16227,
		'task 2': 0, // this should be present, if 0, so it appears in the list
	    },
	    report: {
		'2021-09-29T00:00:00+0100': {
		    'task 1': '04:30:27',
		    total: '04:30:27',
		},
	    },
	},
    },
    {
	name: 'real case 5, xxx',
	log: `1	switch	2022-10-24T19:18:25+0100	2022-10-26T16:32:55+0100	task 3
1	start	2022-10-26T16:32:55+0100	2022-10-26T18:02:59+0100	
1	mark	2022-10-26T18:02:59+0100	2022-10-26T18:12:59+0100	
1	mark	2022-10-26T18:12:59+0100	2022-10-26T18:22:59+0100	
1	stop	2022-10-26T18:22:59+0100	2022-10-26T18:32:59+0100	
1	mark	2022-10-26T18:32:59+0100	2022-10-26T22:26:40+0100	
1	mark	2022-10-26T22:26:40+0100	2022-10-26T22:27:28+0100	
1	start	2022-10-26T22:27:28+0100	2022-10-26T22:32:07+0100	
1	stop	2022-10-26T22:32:07+0100	2022-10-26T22:37:39+0100	
1	mark	2022-10-26T22:37:39+0100	2022-10-27T08:09:26+0100	
1	mark	2022-10-27T08:09:26+0100	2022-10-27T08:18:06+0100	
1	start	2022-10-27T08:18:06+0100	2022-10-27T08:35:21+0100	
1	mark	2022-10-27T08:35:21+0100	2022-10-27T08:44:53+0100	
1	mark	2022-10-27T08:44:53+0100	2022-10-27T08:54:57+0100	
1	mark	2022-10-27T08:54:57+0100	2022-10-27T09:05:05+0100	
1	mark	2022-10-27T09:05:05+0100	2022-10-27T09:14:56+0100	
1	mark	2022-10-27T09:14:56+0100	2022-10-27T09:24:53+0100	
1	mark	2022-10-27T09:24:53+0100	2022-10-27T09:34:53+0100	
1	mark	2022-10-27T09:34:53+0100	2022-10-27T09:44:53+0100	
1	switch	2022-10-27T09:44:53+0100	2022-10-27T09:54:53+0100	task 4
1	mark	2022-10-27T09:54:53+0100	2022-10-27T10:04:53+0100	
1	stop	2022-10-27T10:04:53+0100	2022-10-27T10:14:53+0100	`,
	expect: {
	    tasks: {
		'task 3': 6904,
		'task 4': 1200,
	    },
	    report: {
		'2021-09-29T00:00:00+0100': {
		    'task 1': '01:55:04',
		    'task 2': '00:20:00',
		    total: '02:15:04',
		},
	    },
	},	
    }
];

// Test task parsing
testCases.forEach((c) => {
    const output = Parser.parseTasks(c.log, Parser.mkTaskListAccumulator())
    if (JSON.stringify(output) !== JSON.stringify(c.expect.tasks))
        console.log(c.name,": failed", output);
    else
        console.log(c.name,": passed");
})

// Test JSON report parsing
testCases.forEach((c) => {
    const output = Parser.parseTasks(c.log, Parser.mkReportAccumulator())
    if (JSON.stringify(output) !== JSON.stringify(c.expect.report))
        console.log(c.name,": failed", output);
    else
        console.log(c.name,": passed");
})
